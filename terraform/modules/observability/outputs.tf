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
