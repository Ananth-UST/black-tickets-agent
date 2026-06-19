variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC for security groups."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB over HTTP/HTTPS."
  type        = list(string)
}

variable "app_port" {
  description = "Application port allowed from the ALB to EC2 app instances."
  type        = number
}

variable "rds_port" {
  description = "Database port allowed from EC2 app instances to RDS."
  type        = number
}
