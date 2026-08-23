locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "backup"
  })

  vault_name = "tradecore-${var.environment}-vault"
  plan_name  = "tradecore-${var.environment}-plan"
}

# Backup vault - encrypted with the dedicated backup CMK from the kms module.
# single-region (af-south-1) with no cross-account/cross-region copy

resource "aws_backup_vault" "this" {
  name        = local.vault_name
  kms_key_arn = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.vault_name
  })
}


# Service role AWS Backup assumes to take and restore snapshots on your behalf.

resource "aws_iam_role" "backup" {
  name_prefix = "tradecore-${var.environment}-backup-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowBackupAssumeRole"
        Effect    = "Allow"
        Principal = { Service = "backup.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "tradecore-${var.environment}-backup-role"
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restores" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ---------------------------------------------------------------------------
# Backup plan - single daily rule by default. Add more `rule` blocks in a
# future revision if you need a separate, shorter-retention intra-day rule
# on top of this (AWS Backup plans support multiple rules).
# ---------------------------------------------------------------------------
resource "aws_backup_plan" "this" {
  name = local.plan_name

  rule {
    rule_name                = "tradecore-${var.environment}-daily"
    target_vault_name        = aws_backup_vault.this.name
    schedule                 = var.schedule_expression
    start_window             = var.start_window_minutes
    completion_window        = var.completion_window_minutes

    lifecycle {
      delete_after       = var.retention_days
      cold_storage_after = var.cold_storage_after_days
    }

    recovery_point_tags = merge(local.common_tags, {
      Name = "tradecore-${var.environment}-recovery-point"
    })
  }

  tags = merge(local.common_tags, {
    Name = local.plan_name
  })
}

# ---------------------------------------------------------------------------
# Selection - resources tagged Backup=true are picked up automatically
# (e.g. tag the Aurora cluster and S3 buckets), plus any explicit ARNs
# passed in directly.
# ---------------------------------------------------------------------------
resource "aws_backup_selection" "this" {
  name         = "tradecore-${var.environment}-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this.id

  resources = var.additional_resource_arns

  condition {
    string_equals {
      key   = "aws:ResourceTag/${var.selection_tag_key}"
      value = var.selection_tag_value
    }
  }
}

