data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Main KMS key for TradeCore encryption
resource "aws_kms_key" "tradecore" {
  description             = "Main KMS key for ${var.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "tradecore-${var.environment}-kms"
  }
}

resource "aws_kms_alias" "tradecore" {
  name          = "alias/tradecore-${var.environment}"
  target_key_id = aws_kms_key.tradecore.key_id
}

# KMS key for S3 bucket encryption
resource "aws_kms_key" "s3" {
  description             = "S3 encryption key for ${var.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "tradecore-${var.environment}-s3-key"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/tradecore-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS key for RDS/Aurora encryption
resource "aws_kms_key" "rds" {
  description             = "RDS encryption key for ${var.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "tradecore-${var.environment}-rds-key"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/tradecore-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# KMS key for backup vault encryption
resource "aws_kms_key" "backup" {
  description             = "Backup vault encryption key for ${var.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "tradecore-${var.environment}-backup-key"
  }
}

resource "aws_kms_alias" "backup" {
  name          = "alias/tradecore-${var.environment}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

# KMS key for Secrets Manager encryption
resource "aws_kms_key" "secrets" {
  description             = "Secrets Manager encryption key for ${var.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManagerUse"
        Effect = "Allow"

        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }

        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "tradecore-${var.environment}-secrets-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/tradecore-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
