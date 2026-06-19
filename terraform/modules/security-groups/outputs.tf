output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "private_alb_security_group_id" {
  description = "ID of the private ALB security group."
  value       = aws_security_group.private_alb.id
}

output "ec2_app_security_group_id" {
  description = "ID of the EC2 app security group."
  value       = aws_security_group.ec2_app.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group."
  value       = aws_security_group.vpc_endpoints.id
}
