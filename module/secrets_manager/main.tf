# TradeCore Secrets Manager main

data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "secrets-manager"
  })
}

# Secrets Manager secrets
resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "tradecore-${var.environment}-${each.key}"
  description             = each.value.description
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    local.common_tags,
    each.value.additional_tags,
    {
      Name = "tradecore-${var.environment}-${each.key}"
    }
  )
}

# Optional secret values
#
# Only create a secret version when a value has actually been supplied.
# For production credentials, preferably populate the secret through a
# controlled deployment/bootstrap process rather than storing passwords
# directly in Terraform configuration.

resource "aws_secretsmanager_secret_version" "this" {
  for_each = {
    for name, secret in var.secrets :
    name => secret
    if secret.secret_string != null || secret.secret_string_map != null
  }

  secret_id = aws_secretsmanager_secret.this[each.key].id

  secret_string = (
    each.value.secret_string_map != null
    ? jsonencode(each.value.secret_string_map)
    : each.value.secret_string
  )

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Restrict secret reads to explicitly approved principals
resource "aws_secretsmanager_secret_policy" "this" {
  for_each = length(var.allowed_principal_arns) > 0 ? var.secrets : {}

  secret_arn = aws_secretsmanager_secret.this[each.key].arn

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowNamedPrincipals"
        Effect = "Allow"

        Principal = {
          AWS = var.allowed_principal_arns
        }

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "*"
      },

      {
        Sid       = "DenyOutsideRegion"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret"
        ]

        Resource = "*"

        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      }
    ]
  })
}
