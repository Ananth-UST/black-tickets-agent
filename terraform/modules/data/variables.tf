variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "ID of the RDS security group."
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GB."
  type        = number
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "rds_port" {
  description = "Database port for RDS PostgreSQL."
  type        = number
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

variable "poster_bucket_name" {
  description = "S3 bucket name used for uploaded event poster images."
  type        = string
}

variable "notification_email" {
  description = "Email address subscribed to booking notification messages through SNS."
  type        = string
}
