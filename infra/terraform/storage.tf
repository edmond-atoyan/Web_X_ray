resource "random_id" "model_bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "model" {
  bucket = "${local.name_prefix}-model-${random_id.model_bucket.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-model"
  })
}

resource "aws_s3_bucket_public_access_block" "model" {
  bucket = aws_s3_bucket.model.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "model" {
  bucket = aws_s3_bucket.model.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model" {
  bucket = aws_s3_bucket.model.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "model" {
  bucket       = aws_s3_bucket.model.id
  key          = "models/model.pkl"
  source       = "${path.module}/../../core/main/model.pkl"
  etag         = filemd5("${path.module}/../../core/main/model.pkl")
  content_type = "application/octet-stream"

  tags = local.common_tags
}
