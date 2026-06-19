locals {
  alarm_actions = [module.data.booking_notifications_sns_topic_arn]
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
    LoadBalancer = module.compute.alb_arn_suffix
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
    LoadBalancer = module.compute.private_alb_arn_suffix
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
    AutoScalingGroupName = module.compute.autoscaling_group_name
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
    DBInstanceIdentifier = module.data.rds_instance_identifier
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
    DBInstanceIdentifier = module.data.rds_instance_identifier
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
    FunctionName = module.data.booking_notification_lambda_name
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
    QueueName = module.data.booking_notifications_queue_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-queue-depth-high"
  })
}
