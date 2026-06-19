output "ec2_iam_role_name" {
  description = "Name of the EC2 app IAM role."
  value       = aws_iam_role.ec2_app.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 app instance profile."
  value       = aws_iam_instance_profile.ec2_app.name
}
