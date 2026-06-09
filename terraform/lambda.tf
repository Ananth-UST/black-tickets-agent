data "archive_file" "booking_notification_consumer" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/booking-notification-consumer"
  output_path = "${path.module}/.build/booking-notification-consumer.zip"
}

resource "aws_cloudwatch_log_group" "booking_notification_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-booking-notification-consumer"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-booking-notification-consumer-logs"
  })
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "booking_notification_lambda" {
  name               = "${local.name_prefix}-booking-notification-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-booking-notification-lambda-role"
  })
}

data "aws_iam_policy_document" "booking_notification_consumer" {
  statement {
    sid = "WriteCloudWatchLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.booking_notification_lambda.arn}:*"
    ]
  }

  statement {
    sid = "ReadBookingNotificationQueue"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]

    resources = [
      aws_sqs_queue.booking_notifications.arn
    ]
  }

  statement {
    sid = "PublishBookingNotifications"

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.booking_notifications.arn
    ]
  }
}

resource "aws_iam_role_policy" "booking_notification_lambda" {
  name   = "${local.name_prefix}-booking-notification-lambda-policy"
  role   = aws_iam_role.booking_notification_lambda.id
  policy = data.aws_iam_policy_document.booking_notification_consumer.json
}

resource "aws_lambda_function" "booking_notification_consumer" {
  function_name    = "${local.name_prefix}-booking-notification-consumer"
  role             = aws_iam_role.booking_notification_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 3
  memory_size      = 128
  filename         = data.archive_file.booking_notification_consumer.output_path
  source_code_hash = data.archive_file.booking_notification_consumer.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.booking_notifications.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.booking_notification_lambda,
    aws_iam_role_policy.booking_notification_lambda
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-booking-notification-consumer"
  })
}

resource "aws_lambda_event_source_mapping" "booking_notification_consumer" {
  event_source_arn = aws_sqs_queue.booking_notifications.arn
  function_name    = aws_lambda_function.booking_notification_consumer.arn
  enabled          = true
  batch_size       = 5
}
