resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id = "abort-incomplete"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    status = "Enabled"
    filter {} # Apply to all objects
  }

  rule {
    id = "expire-all"
    expiration {
      days = var.expiration_days
    }
    status = "Enabled"
    filter {} # Apply to all objects
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
