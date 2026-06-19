locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  alarm_actions         = [var.sns_topic_arn]
  cloudtrail_name       = "blacktickets-dev-trail"
  cloudtrail_bucket     = "blacktickets-dev-cloudtrail-logs"
  cloudtrail_log_group  = "/aws/cloudtrail/blacktickets-dev"
  cloudtrail_source_arn = "arn:aws:cloudtrail:${var.aws_region}:${var.account_id}:trail/${local.cloudtrail_name}"
}

resource "aws_cloudwatch_metric_alarm" "public_alb_5xx_errors" {
  alarm_name          = "${local.name_prefix}-public-alb-5xx-errors"
  alarm_description   = "Public ALB has at least 5 ELB 5XX errors in 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5
  period              = 300
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    LoadBalancer = var.public_alb_arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-alb-5xx-errors"
  })
}

resource "aws_cloudwatch_metric_alarm" "private_alb_target_5xx_errors" {
  alarm_name          = "${local.name_prefix}-private-alb-target-5xx-errors"
  alarm_description   = "Private ALB targets have at least 5 target 5XX errors in 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5
  period              = 300
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    LoadBalancer = var.private_alb_arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-alb-target-5xx-errors"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-high"
  alarm_description   = "EC2 average CPU utilization is at least 80% for 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 80
  period              = 300
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS PostgreSQL CPU utilization is at least 80% for 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 80
  period              = 300
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${local.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS PostgreSQL free storage is 5 GB or lower."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5368709120
  period              = 300
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-free-storage-low"
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-errors"
  alarm_description   = "Booking notification Lambda has at least 1 error in 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  period              = 300
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-errors"
  })
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth_high" {
  alarm_name          = "${local.name_prefix}-sqs-queue-depth-high"
  alarm_description   = "Booking notifications SQS queue has at least 10 visible messages."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 10
  period              = 300
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-queue-depth-high"
  })
}

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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.public_alb_arn_suffix, { label = "Request Count", stat = "Sum" }],
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.private_alb_arn_suffix, { label = "Request Count", stat = "Sum" }],
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
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.autoscaling_group_name, { label = "In-Service Instances" }],
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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.autoscaling_group_name, { label = "CPU Utilization" }]
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
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_identifier, { label = "CPU Utilization" }],
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
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name, { label = "Invocations", stat = "Sum" }],
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
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name, { label = "Visible Messages", stat = "Average" }],
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
            ["AWS/CloudFront", "Requests", "DistributionId", var.poster_cloudfront_distribution_id, "Region", "Global", { label = "Requests", stat = "Sum" }],
            [".", "BytesDownloaded", ".", ".", ".", ".", { label = "Bytes Downloaded", stat = "Sum", yAxis = "right" }]
          ]
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.cloudtrail_bucket

  tags = merge(local.common_tags, {
    Name = local.cloudtrail_bucket
  })
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "cloudtrail-log-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid = "AWSCloudTrailAclCheck"

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.cloudtrail_logs.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }
  }

  statement {
    sid = "AWSCloudTrailWrite"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${var.account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = local.cloudtrail_log_group
  retention_in_days = 90

  tags = merge(local.common_tags, {
    Name = local.cloudtrail_log_group
  })
}

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_logs" {
  name               = "${local.name_prefix}-cloudtrail-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudtrail-cloudwatch-logs-role"
  })
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    sid = "WriteCloudTrailLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:${var.account_id}_CloudTrail_*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_logs" {
  name   = "${local.name_prefix}-cloudtrail-cloudwatch-logs-policy"
  role   = aws_iam_role.cloudtrail_cloudwatch_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

resource "aws_cloudtrail" "main" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_logs.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${var.poster_bucket_arn}/"
      ]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_iam_role_policy.cloudtrail_cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = local.cloudtrail_name
  })
}

resource "aws_wafv2_web_acl" "public_alb" {
  name        = "blacktickets-dev-web-acl"
  description = "Regional WAF Web ACL for the BlackTickets public ALB."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"

          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit100"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit100"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "blacktickets-dev-web-acl"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "blacktickets-dev-web-acl"
  })
}

resource "aws_wafv2_web_acl_association" "public_alb" {
  resource_arn = var.public_alb_arn
  web_acl_arn  = aws_wafv2_web_acl.public_alb.arn
}
