variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for VPC endpoint service names."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  type        = list(string)
}

variable "vpc_endpoint_security_group_id" {
  description = "ID of the VPC endpoints security group."
  type        = string
}

variable "private_route_table_ids" {
  description = "IDs of the route tables associated with the S3 gateway endpoint."
  type        = list(string)
}
