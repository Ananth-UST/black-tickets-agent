output "account_id" {
  description = "Current AWS account ID."
  value       = data.aws_caller_identity.current.account_id
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

output "alb_arn_suffix" {
  description = "ARN suffix of the public Application Load Balancer."
  value       = aws_lb.public.arn_suffix
}

output "private_alb_arn_suffix" {
  description = "ARN suffix of the private Application Load Balancer."
  value       = aws_lb.private.arn_suffix
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
