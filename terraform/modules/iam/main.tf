locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_app" {
  name               = "${local.name_prefix}-ec2-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-app-role"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read_only" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_manager_read_write" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2_poster_bucket_access" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      "arn:aws:s3:::${var.poster_bucket_name}/event-posters/*"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_poster_bucket_access" {
  name   = "${local.name_prefix}-poster-bucket-access"
  role   = aws_iam_role.ec2_app.id
  policy = data.aws_iam_policy_document.ec2_poster_bucket_access.json
}

data "aws_iam_policy_document" "ec2_booking_notifications_sqs" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes"
    ]

    resources = [
      var.booking_notifications_queue_arn
    ]
  }
}

resource "aws_iam_role_policy" "ec2_booking_notifications_sqs" {
  name   = "${local.name_prefix}-booking-notifications-sqs"
  role   = aws_iam_role.ec2_app.id
  policy = data.aws_iam_policy_document.ec2_booking_notifications_sqs.json
}

data "aws_iam_policy_document" "ec2_bedrock_invoke" {
  statement {
    actions = [
      "bedrock:InvokeModel"
    ]

    resources = [
      "arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-micro-v1:0"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_bedrock_invoke" {
  name   = "${local.name_prefix}-bedrock-invoke"
  role   = aws_iam_role.ec2_app.id
  policy = data.aws_iam_policy_document.ec2_bedrock_invoke.json
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${local.name_prefix}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-app-profile"
  })
}
