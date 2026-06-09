variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
  default     = "blacktickets"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB over HTTP/HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Application port allowed from the ALB to EC2 app instances."
  type        = number
  default     = 80
}

variable "rds_port" {
  description = "Database port allowed from EC2 app instances to RDS."
  type        = number
  default     = 5432
}

variable "ec2_instance_type" {
  description = "EC2 instance type for application instances."
  type        = string
  default     = "t3.small"
}

variable "ec2_key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "ecr_image_tag" {
  description = "Container image tag to pull from ECR."
  type        = string
  default     = "latest"
}

variable "alb_health_check_path" {
  description = "Health check path for the ALB target group."
  type        = string
  default     = "/"
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "identity_db"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "postgres"
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GB."
  type        = number
  default     = 20
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret for application services."
  type        = string
  sensitive   = true
}

variable "internal_service_token" {
  description = "Shared internal service token for service-to-service requests."
  type        = string
  sensitive   = true
}

variable "poster_bucket_name" {
  description = "S3 bucket name used for uploaded event poster images."
  type        = string
}

variable "admin_email" {
  description = "Seed admin user email for identity-service startup."
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Seed admin user password for identity-service startup."
  type        = string
  sensitive   = true
}

variable "user_email" {
  description = "Seed standard user email for identity-service startup."
  type        = string
  sensitive   = true
}

variable "user_password" {
  description = "Seed standard user password for identity-service startup."
  type        = string
  sensitive   = true
}
