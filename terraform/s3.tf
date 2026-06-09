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
