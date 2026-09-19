output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_ec2_id" {
  value = aws_instance.app_server.id
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}