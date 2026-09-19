terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "failure-prediction-vpc"
  }
}

# =========================================================
# INTERNET GATEWAY
# =========================================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "failure-prediction-igw"
  }
}

# =========================================================
# PUBLIC SUBNETS
# =========================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "failure-prediction-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "failure-prediction-public-b"
  }
}

# =========================================================
# PRIVATE APPLICATION SUBNETS
# =========================================================

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "failure-prediction-private-app-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "failure-prediction-private-app-b"
  }
}

# =========================================================
# PRIVATE DATABASE SUBNETS
# =========================================================

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "failure-prediction-db-a"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "failure-prediction-db-b"
  }
}

# =========================================================
# PUBLIC ROUTE TABLE
# =========================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "failure-prediction-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# =========================================================
# NAT GATEWAY
# =========================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "failure-prediction-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "failure-prediction-nat"
  }
}

# =========================================================
# PRIVATE ROUTE TABLE
# =========================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "failure-prediction-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.private.id
}

# =========================================================
# ALB SECURITY GROUP
# =========================================================

resource "aws_security_group" "alb" {
  name   = "failure-prediction-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "failure-prediction-alb-sg"
  }
}

# =========================================================
# APPLICATION EC2 SECURITY GROUP
# =========================================================

resource "aws_security_group" "app" {
  name   = "failure-prediction-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "failure-prediction-app-sg"
  }
}

# =========================================================
# RDS SECURITY GROUP
# =========================================================

resource "aws_security_group" "rds" {
  name   = "failure-prediction-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "failure-prediction-rds-sg"
  }
}

# =========================================================
# IAM ROLE FOR PRIVATE EC2
# =========================================================

resource "aws_iam_role" "ec2_role" {
  name = "failure-prediction-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "failure-prediction-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "failure-prediction-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# =========================================================
# AMAZON LINUX 2023 AMI
# =========================================================

data "aws_ami" "al2023" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# =========================================================
# PRIVATE EC2
# =========================================================

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.private_a.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash

              dnf update -y

              dnf install -y docker git curl java-17-amazon-corretto-devel

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ec2-user

              curl -sfL https://get.k3s.io | sh -

              systemctl enable k3s
              systemctl start k3s

              mkdir -p /home/ec2-user/.kube

              cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config

              chown -R ec2-user:ec2-user /home/ec2-user/.kube

              chmod 600 /home/ec2-user/.kube/config

              EOF

  tags = {
    Name = "failure-prediction-private-ec2"
  }
}

# =========================================================
# APPLICATION LOAD BALANCER
# =========================================================

resource "aws_lb" "app" {
  name               = "failure-prediction-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "failure-prediction-alb"
  }
}

# =========================================================
# ALB TARGET GROUP
# =========================================================

resource "aws_lb_target_group" "app" {
  name     = "failure-prediction-tg"
  port     = 30080
  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "30080"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "failure-prediction-target-group"
  }
}

# =========================================================
# EC2 → ALB TARGET GROUP
# =========================================================

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn

  target_id = aws_instance.app_server.id

  port = 30080
}

# =========================================================
# ALB LISTENER
# =========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# =========================================================
# RDS SUBNET GROUP
# =========================================================

resource "aws_db_subnet_group" "rds" {
  name = "failure-prediction-db-subnet-group"

  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]

  tags = {
    Name = "failure-prediction-db-subnet-group"
  }
}

# =========================================================
# RANDOM DATABASE PASSWORD
# =========================================================

resource "random_password" "db" {
  length  = 20
  special = false
}

# =========================================================
# RDS POSTGRESQL
# =========================================================

resource "aws_db_instance" "postgres" {
  identifier = "failure-prediction-db"

  engine         = "postgres"
  engine_version = "16"

  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name = aws_db_subnet_group.rds.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  storage_encrypted = true

  backup_retention_period = 1

  skip_final_snapshot = true

  tags = {
    Name = "failure-prediction-database"
  }
}

# =========================================================
# SECRETS MANAGER
# =========================================================

resource "aws_secretsmanager_secret" "db" {
  name = "failure-prediction/database"

  tags = {
    Name = "failure-prediction-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    database = var.db_name
    host     = aws_db_instance.postgres.address
    port     = 5432
  })
}