locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  port                   = var.rds_port
  multi_az               = false
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres"
  })
}

resource "aws_sqs_queue" "booking_notifications" {
  name                       = "blacktickets-dev-booking-notifications"
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  tags = merge(local.common_tags, {
    Name = "blacktickets-dev-booking-notifications"
  })
}

resource "aws_secretsmanager_secret" "app_config" {
  name        = "${local.name_prefix}/app-config"
  description = "Runtime configuration for BlackTickets application services."

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-config-secret"
  })
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id

  secret_string = jsonencode({
    DB_HOST                        = aws_db_instance.postgres.address
    DB_PORT                        = tostring(var.rds_port)
    DB_USER                        = var.db_username
    DB_PASSWORD                    = var.db_password
    JWT_SECRET                     = var.jwt_secret
    INTERNAL_SERVICE_TOKEN         = var.internal_service_token
    BOOKING_NOTIFICATION_QUEUE_URL = aws_sqs_queue.booking_notifications.url
    ADMIN_EMAIL                    = var.admin_email
    ADMIN_PASSWORD                 = var.admin_password
    USER_EMAIL                     = var.user_email
    USER_PASSWORD                  = var.user_password
  })
}

resource "aws_s3_bucket" "posters" {
  bucket = var.poster_bucket_name

  tags = merge(local.common_tags, {
    Name = var.poster_bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "posters" {
  bucket = aws_s3_bucket.posters.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "posters" {
  bucket = aws_s3_bucket.posters.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "posters" {
  bucket = aws_s3_bucket.posters.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "posters" {
  bucket = aws_s3_bucket.posters.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_cloudfront_origin_access_control" "posters" {
  name                              = "${local.name_prefix}-poster-oac"
  description                       = "OAC for private event poster bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "posters" {
  enabled             = true
  comment             = "${local.name_prefix} poster images"
  default_root_object = ""

  origin {
    domain_name              = aws_s3_bucket.posters.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.posters.id
    origin_id                = "poster-s3-origin"
  }

  default_cache_behavior {
    target_origin_id       = "poster-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-poster-cdn"
  })
}

data "aws_iam_policy_document" "poster_bucket_cloudfront_read" {
  statement {
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.posters.arn}/event-posters/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.posters.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "posters" {
  bucket = aws_s3_bucket.posters.id
  policy = data.aws_iam_policy_document.poster_bucket_cloudfront_read.json
}

resource "aws_sns_topic" "booking_notifications" {
  name = "blacktickets-dev-booking-notifications"

  tags = merge(local.common_tags, {
    Name = "blacktickets-dev-booking-notifications"
  })
}

resource "aws_sns_topic_subscription" "booking_notifications_email" {
  topic_arn = aws_sns_topic.booking_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

data "archive_file" "booking_notification_consumer" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/booking-notification-consumer"
  output_path = "${path.root}/.build/booking-notification-consumer.zip"
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
