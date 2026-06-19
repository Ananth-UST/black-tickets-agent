resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "BlackTickets-Operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "Public ALB"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.compute.alb_arn_suffix, { label = "Request Count", stat = "Sum" }],
            [".", "TargetResponseTime", ".", ".", { label = "Target Response Time", stat = "Average", yAxis = "right" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { label = "ELB 5XX Count", stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "Private ALB"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.compute.private_alb_arn_suffix, { label = "Request Count", stat = "Sum" }],
            [".", "TargetResponseTime", ".", ".", { label = "Target Response Time", stat = "Average", yAxis = "right" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { label = "Target 5XX Count", stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "Auto Scaling Group"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", module.compute.autoscaling_group_name, { label = "In-Service Instances" }],
            [".", "GroupDesiredCapacity", ".", ".", { label = "Desired Capacity" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "EC2"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.compute.autoscaling_group_name, { label = "CPU Utilization" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "RDS PostgreSQL"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", module.data.rds_instance_identifier, { label = "CPU Utilization" }],
            [".", "DatabaseConnections", ".", ".", { label = "Database Connections" }],
            [".", "FreeStorageSpace", ".", ".", { label = "Free Storage Space", yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "Lambda"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.data.booking_notification_lambda_name, { label = "Invocations", stat = "Sum" }],
            [".", "Errors", ".", ".", { label = "Errors", stat = "Sum" }],
            [".", "Duration", ".", ".", { label = "Duration", stat = "Average", yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "SQS"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", module.data.booking_notifications_queue_name, { label = "Visible Messages", stat = "Average" }],
            [".", "NumberOfMessagesSent", ".", ".", { label = "Messages Sent", stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "CloudFront"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", module.data.poster_cloudfront_distribution_id, "Region", "Global", { label = "Requests", stat = "Sum" }],
            [".", "BytesDownloaded", ".", ".", ".", ".", { label = "Bytes Downloaded", stat = "Sum", yAxis = "right" }]
          ]
        }
      }
    ]
  })
}
