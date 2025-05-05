resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket.json
}

data "aws_iam_policy_document" "bucket" {
  dynamic "statement" {
    for_each = toset(length(var.full_access_principals) > 0 ? [0] : [])
    content {
      principals {
        type        = "AWS"
        identifiers = var.full_access_principals
      }
      resources = [aws_s3_bucket.bucket.arn, "${aws_s3_bucket.bucket.arn}/*"]
      actions = [
        "s3:ListBucket",

        "s3:GetObject",
        "s3:GetObjectVersion",

        "s3:PutObject",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload",

        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
      ]
    }
  }

  dynamic "statement" {
    for_each = toset(length(var.rw_access_principals) > 0 ? [0] : [])
    content {
      principals {
        type        = "AWS"
        identifiers = var.rw_access_principals
      }
      resources = [aws_s3_bucket.bucket.arn, "${aws_s3_bucket.bucket.arn}/*"]
      actions = [
        "s3:ListBucket",

        "s3:GetObject",
        "s3:GetObjectVersion",

        "s3:PutObject",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload",
      ]
    }
  }

  dynamic "statement" {
    for_each = toset(length(var.ro_access_principals) > 0 ? [0] : [])
    content {
      principals {
        type        = "AWS"
        identifiers = var.ro_access_principals
      }
      resources = [aws_s3_bucket.bucket.arn, "${aws_s3_bucket.bucket.arn}/*"]
      actions = [
        "s3:ListBucket",

        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
    }
  }

  dynamic "statement" {
    for_each = toset(length(var.wo_access_principals) > 0 ? [0] : [])
    content {
      principals {
        type        = "AWS"
        identifiers = var.wo_access_principals
      }
      resources = [aws_s3_bucket.bucket.arn, "${aws_s3_bucket.bucket.arn}/*"]
      actions = [
        "s3:ListBucket",

        "s3:PutObject",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload",
      ]
    }
  }
}
