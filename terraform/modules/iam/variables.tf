variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "poster_bucket_name" {
  description = "S3 bucket name used for uploaded event poster images."
  type        = string
}

variable "booking_notifications_queue_arn" {
  description = "ARN of the booking notifications SQS queue."
  type        = string
}

variable "app_config_secret_arn" {
  description = "ARN of the Secrets Manager app config secret readable by EC2 app instances."
  type        = string
}
