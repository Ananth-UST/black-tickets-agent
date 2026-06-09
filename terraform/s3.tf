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
