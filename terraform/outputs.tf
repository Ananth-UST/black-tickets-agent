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
  value       = aws_launch_template.app.id
}

output "alb_arn" {
  description = "ARN of the public Application Load Balancer."
  value       = aws_lb.public.arn
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer."
  value       = aws_lb.public.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the public Application Load Balancer."
  value       = aws_lb.public.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the frontend ALB target group."
  value       = aws_lb_target_group.frontend.arn
}

output "alb_http_listener_arn" {
  description = "ARN of the public HTTP ALB listener."
  value       = aws_lb_listener.public_http.arn
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
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
  value       = aws_db_instance.postgres.address
}

output "app_config_secret_arn" {
  description = "ARN of the Secrets Manager secret containing app runtime config."
  value       = aws_secretsmanager_secret.app_config.arn
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
  value       = aws_s3_bucket.posters.bucket
}

output "poster_cloudfront_domain_name" {
  description = "CloudFront domain name for private S3 poster images."
  value       = aws_cloudfront_distribution.posters.domain_name
}

output "public_alb_dns_name" {
  description = "DNS name of the public frontend ALB."
  value       = aws_lb.public.dns_name
}

output "private_alb_dns_name" {
  description = "DNS name of the private backend ALB."
  value       = aws_lb.private.dns_name
}

output "backend_target_group_arns" {
  description = "ARNs of backend service target groups."
  value = {
    identity = aws_lb_target_group.identity.arn
    event    = aws_lb_target_group.event.arn
    booking  = aws_lb_target_group.booking.arn
    chatbot  = aws_lb_target_group.chatbot.arn
  }
}

output "booking_notifications_queue_url" {
  description = "URL of the booking notifications SQS queue."
  value       = aws_sqs_queue.booking_notifications.url
}

output "booking_notifications_queue_arn" {
  description = "ARN of the booking notifications SQS queue."
  value       = aws_sqs_queue.booking_notifications.arn
}

output "booking_notification_lambda_name" {
  description = "Name of the booking notification Lambda consumer."
  value       = aws_lambda_function.booking_notification_consumer.function_name
}

output "booking_notification_lambda_arn" {
  description = "ARN of the booking notification Lambda consumer."
  value       = aws_lambda_function.booking_notification_consumer.arn
}

output "booking_notifications_sns_topic_arn" {
  description = "ARN of the SNS topic used for booking notification emails."
  value       = aws_sns_topic.booking_notifications.arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch operations dashboard."
  value       = aws_cloudwatch_dashboard.operations.dashboard_name
}

output "cloudwatch_alarm_names" {
  description = "Names of the CloudWatch alarms for BlackTickets operations."
  value = [
    aws_cloudwatch_metric_alarm.public_alb_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.private_alb_target_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.ec2_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_free_storage_low.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.sqs_queue_depth_high.alarm_name
  ]
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL associated with the public ALB."
  value       = aws_wafv2_web_acl.public_alb.arn
}

output "waf_web_acl_name" {
  description = "Name of the WAF Web ACL associated with the public ALB."
  value       = aws_wafv2_web_acl.public_alb.name
}

output "cloudtrail_name" {
  description = "Name of the BlackTickets CloudTrail trail."
  value       = aws_cloudtrail.main.name
}

output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket that stores CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudWatch log group that receives CloudTrail events."
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "tfstate_bucket_name" {
  description = "Name of the S3 bucket prepared for Terraform remote state."
  value       = aws_s3_bucket.tfstate.bucket
}

output "terraform_lock_table_name" {
  description = "Name of the DynamoDB table prepared for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}
