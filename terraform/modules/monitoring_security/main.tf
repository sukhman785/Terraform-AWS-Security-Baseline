data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  cloudtrail_name = "${var.project_name}-${var.environment}-trail"
  cloudtrail_arn  = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-${var.environment}-trail"
  bucket_name     = lower("${var.project_name}-${var.environment}-cloudtrail-${data.aws_caller_identity.current.account_id}")
}

#checkov:skip=CKV2_AWS_61:Lifecycle is implemented via a dedicated aws_s3_bucket_lifecycle_configuration resource.
#checkov:skip=CKV_AWS_21:Versioning is implemented via a dedicated aws_s3_bucket_versioning resource.
#checkov:skip=CKV2_AWS_6:Public access block is implemented via a dedicated aws_s3_bucket_public_access_block resource.
#checkov:skip=CKV_AWS_145:KMS encryption is implemented via a dedicated aws_s3_bucket_server_side_encryption_configuration resource.
resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  bucket = local.bucket_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudtrail-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count  = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count  = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  count = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy[0].json
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count  = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "cloudtrail-log-retention"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}"
  retention_in_days = var.cloudtrail_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudtrail-log-group"
    Environment = var.environment
  }
}

resource "aws_sns_topic" "cloudtrail" {
  count             = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  name              = "${var.project_name}-${var.environment}-cloudtrail-alerts"
  kms_master_key_id = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudtrail-alerts"
    Environment = var.environment
  }
}

resource "aws_iam_role" "cloudtrail" {
  count = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudtrail-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cloudtrail-to-cloudwatch"
  role  = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  #checkov:skip=CKV2_AWS_10:CloudWatch integration is configured via cloud_watch_logs_group_arn and cloud_watch_logs_role_arn.
  count                         = var.enable_runtime_security && var.enable_cloudtrail ? 1 : 0
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail[0].arn
  kms_key_id                    = var.kms_key_arn
  sns_topic_name                = aws_sns_topic.cloudtrail[0].name

  depends_on = [
    aws_s3_bucket_policy.cloudtrail
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-trail"
    Environment = var.environment
  }
}

resource "aws_guardduty_detector" "main" {
  count  = var.enable_runtime_security && var.enable_guardduty ? 1 : 0
  enable = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-guardduty"
    Environment = var.environment
  }
}

resource "aws_securityhub_account" "main" {
  count = var.enable_runtime_security && var.enable_security_hub ? 1 : 0
}
