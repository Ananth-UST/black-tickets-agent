variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets."
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group."
  type        = string
}

variable "private_alb_security_group_id" {
  description = "ID of the private ALB security group."
  type        = string
}

variable "ec2_app_security_group_id" {
  description = "ID of the EC2 app security group."
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Name of the EC2 app instance profile."
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type for application instances."
  type        = string
}

variable "ec2_key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
}

variable "ecr_image_tag" {
  description = "Container image tag to pull from ECR."
  type        = string
}

variable "app_config_secret_arn" {
  description = "ARN of the Secrets Manager secret containing app runtime config."
  type        = string
}

variable "poster_bucket_name" {
  description = "S3 bucket name used for uploaded event poster images."
  type        = string
}

variable "poster_cdn_domain" {
  description = "CloudFront domain name for private S3 poster images."
  type        = string
}
