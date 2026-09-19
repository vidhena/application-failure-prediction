variable "aws_region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "db_username" {
  default = "appadmin"
}

variable "db_name" {
  default = "failuredb"
}