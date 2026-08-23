data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Bucket - CloudTrail log storage
resource "aws_s3_bucket" "trail" {
  bucket        = var.trail_bucket_name
  force_destroy = var.force_destroy_bucket

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket = aws_s3_bucket.trail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  count  = var.log_expiration_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.trail.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = var.log_expiration_days
    }
  }
}

# Required bucket policy allowing CloudTrail to write logs
data "aws_iam_policy_document" "trail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket_policy.json
}

# CloudWatch Log Group - optional, for near-real-time log analysis
resource "aws_cloudwatch_log_group" "trail" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/cloudtrail/${var.trail_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.tags
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.trail_name}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.trail_name}-cloudtrail-cloudwatch-policy"
  role  = aws_iam_role.cloudtrail_to_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.trail[0].arn}:*"
    }]
  })
}

# CloudTrail
resource "aws_cloudtrail" "this" {
  name           = var.trail_name
  s3_bucket_name = aws_s3_bucket.trail.id
  s3_key_prefix  = var.s3_key_prefix

  is_multi_region_trail        = var.is_multi_region_trail
  is_organization_trail        = var.is_organization_trail
  include_global_service_events = var.include_global_service_events
  enable_log_file_validation   = var.enable_log_file_validation

  kms_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.trail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_to_cloudwatch[0].arn : null

  sns_topic_name = var.enable_sns_notifications ? aws_sns_topic.trail_notifications[0].name : null

  dynamic "event_selector" {
    for_each = var.event_selectors
    content {
      read_write_type           = event_selector.value.read_write_type
      include_management_events = event_selector.value.include_management_events

      dynamic "data_resource" {
        for_each = event_selector.value.data_resources
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  tags = var.tags

  depends_on = [aws_s3_bucket_policy.trail, aws_sns_topic_policy.trail_notifications]
}

# SNS Topic - optional, notify on new log file delivery
resource "aws_sns_topic" "trail_notifications" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "${var.trail_name}-notifications"

  tags = var.tags
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.enable_sns_notifications ? 1 : 0

  statement {
    sid     = "AllowCloudTrailPublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = [aws_sns_topic.trail_notifications[0].arn]
  }
}

resource "aws_sns_topic_policy" "trail_notifications" {
  count  = var.enable_sns_notifications ? 1 : 0
  arn    = aws_sns_topic.trail_notifications[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

resource "aws_sns_topic_subscription" "trail_email" {
  count     = var.enable_sns_notifications && var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.trail_notifications[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

