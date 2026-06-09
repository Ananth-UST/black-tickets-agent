output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = aws_subnet.private_db[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "IDs of the private app route tables."
  value       = aws_route_table.private_app[*].id
}

output "private_db_route_table_ids" {
  description = "IDs of the private database route tables."
  value       = aws_route_table.private_db[*].id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "ec2_app_security_group_id" {
  description = "ID of the EC2 app security group."
  value       = aws_security_group.ec2_app.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}

output "ec2_iam_role_name" {
  description = "Name of the EC2 app IAM role."
  value       = aws_iam_role.ec2_app.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 app instance profile."
  value       = aws_iam_instance_profile.ec2_app.name
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
  value       = aws_security_group.vpc_endpoints.id
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
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway Elastic IP."
  value       = aws_eip.nat.public_ip
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
