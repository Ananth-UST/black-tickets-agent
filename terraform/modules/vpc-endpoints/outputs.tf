output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "secretsmanager_endpoint_id" {
  description = "ID of the Secrets Manager interface VPC endpoint."
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "ssm_endpoint_id" {
  description = "ID of the SSM interface VPC endpoint."
  value       = aws_vpc_endpoint.ssm.id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API interface VPC endpoint."
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR Docker interface VPC endpoint."
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "cloudwatch_logs_endpoint_id" {
  description = "ID of the CloudWatch Logs interface VPC endpoint."
  value       = aws_vpc_endpoint.cloudwatch_logs.id
}

output "ssm_messages_endpoint_id" {
  description = "ID of the SSM Messages interface VPC endpoint."
  value       = aws_vpc_endpoint.ssm_messages.id
}

output "ec2_messages_endpoint_id" {
  description = "ID of the EC2 Messages interface VPC endpoint."
  value       = aws_vpc_endpoint.ec2_messages.id
}
