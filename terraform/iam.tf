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

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${local.name_prefix}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-app-profile"
  })
}
