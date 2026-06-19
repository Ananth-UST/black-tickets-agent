output "vpc_id" {
  description = "ID of the VPC."
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.networking.vpc_cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = module.networking.internet_gateway_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = module.networking.private_db_subnet_ids
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = module.networking.public_route_table_id
}

output "private_app_route_table_ids" {
  description = "IDs of the private app route tables."
  value       = module.networking.private_app_route_table_ids
}

output "private_db_route_table_ids" {
  description = "IDs of the private database route tables."
  value       = module.networking.private_db_route_table_ids
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = module.security_groups.alb_security_group_id
}

output "ec2_app_security_group_id" {
  description = "ID of the EC2 app security group."
  value       = module.security_groups.ec2_app_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = module.security_groups.rds_security_group_id
}

output "ec2_iam_role_name" {
  description = "Name of the EC2 app IAM role."
  value       = module.iam.ec2_iam_role_name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 app instance profile."
  value       = module.iam.ec2_instance_profile_name
}

output "launch_template_id" {
  description = "ID of the EC2 app launch template."
  value       = module.compute.launch_template_id
}

output "alb_arn" {
  description = "ARN of the public Application Load Balancer."
  value       = module.compute.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer."
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the public Application Load Balancer."
  value       = module.compute.alb_zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the frontend ALB target group."
  value       = module.compute.alb_target_group_arn
}

output "alb_http_listener_arn" {
  description = "ARN of the public HTTP ALB listener."
  value       = module.compute.alb_http_listener_arn
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = module.compute.autoscaling_group_name
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group."
  value       = module.security_groups.vpc_endpoints_security_group_id
}

output "s3_gateway_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "interface_endpoint_ids" {
  description = "IDs of the interface VPC endpoints."
  value = {
    ecr_api         = aws_vpc_endpoint.ecr_api.id
    ecr_dkr         = aws_vpc_endpoint.ecr_dkr.id
    secretsmanager  = aws_vpc_endpoint.secretsmanager.id
    cloudwatch_logs = aws_vpc_endpoint.cloudwatch_logs.id
    ssm             = aws_vpc_endpoint.ssm.id
    ssm_messages    = aws_vpc_endpoint.ssm_messages.id
    ec2_messages    = aws_vpc_endpoint.ec2_messages.id
  }
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint address."
  value       = module.data.rds_endpoint
}

output "app_config_secret_arn" {
  description = "ARN of the Secrets Manager secret containing app runtime config."
  value       = module.data.app_config_secret_arn
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway used by private app subnets."
  value       = module.networking.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway Elastic IP."
  value       = module.networking.nat_gateway_public_ip
}

output "poster_bucket_name" {
  description = "Name of the S3 bucket used for event poster uploads."
  value       = module.data.poster_bucket_name
}

output "poster_cloudfront_domain_name" {
  description = "CloudFront domain name for private S3 poster images."
  value       = module.data.poster_cloudfront_domain_name
}

output "public_alb_dns_name" {
  description = "DNS name of the public frontend ALB."
  value       = module.compute.public_alb_dns_name
}

output "private_alb_dns_name" {
  description = "DNS name of the private backend ALB."
  value       = module.compute.private_alb_dns_name
}

output "backend_target_group_arns" {
  description = "ARNs of backend service target groups."
  value = {
    identity = module.compute.backend_target_group_arns.identity
    event    = module.compute.backend_target_group_arns.event
    booking  = module.compute.backend_target_group_arns.booking
    chatbot  = module.compute.backend_target_group_arns.chatbot
  }
}

output "booking_notifications_queue_url" {
  description = "URL of the booking notifications SQS queue."
  value       = module.data.booking_notifications_queue_url
}

output "booking_notifications_queue_arn" {
  description = "ARN of the booking notifications SQS queue."
  value       = module.data.booking_notifications_queue_arn
}

output "booking_notification_lambda_name" {
  description = "Name of the booking notification Lambda consumer."
  value       = module.data.booking_notification_lambda_name
}

output "booking_notification_lambda_arn" {
  description = "ARN of the booking notification Lambda consumer."
  value       = module.data.booking_notification_lambda_arn
}

output "booking_notifications_sns_topic_arn" {
  description = "ARN of the SNS topic used for booking notification emails."
  value       = module.data.booking_notifications_sns_topic_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch operations dashboard."
  value       = module.observability.cloudwatch_dashboard_name
}

output "cloudwatch_alarm_names" {
  description = "Names of the CloudWatch alarms for BlackTickets operations."
  value       = module.observability.cloudwatch_alarm_names
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL associated with the public ALB."
  value       = module.observability.waf_web_acl_arn
}

output "waf_web_acl_name" {
  description = "Name of the WAF Web ACL associated with the public ALB."
  value       = module.observability.waf_web_acl_name
}

output "cloudtrail_name" {
  description = "Name of the BlackTickets CloudTrail trail."
  value       = module.observability.cloudtrail_name
}

output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket that stores CloudTrail logs."
  value       = module.observability.cloudtrail_bucket_name
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudWatch log group that receives CloudTrail events."
  value       = module.observability.cloudtrail_log_group_name
}

output "tfstate_bucket_name" {
  description = "Name of the S3 bucket prepared for Terraform remote state."
  value       = aws_s3_bucket.tfstate.bucket
}

output "terraform_lock_table_name" {
  description = "Name of the DynamoDB table prepared for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}
