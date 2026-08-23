
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ============================================================
# ECS TASK EXECUTION ROLE
# ============================================================
#
# This role is assumed by ECS/Fargate itself.
#
# It allows ECS to:
# - Pull container images from ECR
# - Write container logs to CloudWatch
# - Retrieve secrets used by the ECS task
# - Decrypt encrypted secrets using KMS
#

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}


# Basic AWS-managed ECS execution permissions
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role = aws_iam_role.ecs_task_execution.name

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ============================================================
# ADDITIONAL ECS EXECUTION PERMISSIONS
# ============================================================
#
# The standard ECS execution policy does not automatically give
# access to your customer-managed Secrets Manager/KMS resources.
#

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${local.name_prefix}-ecs-execution-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = concat(
      length(var.secrets_arns) > 0 ? [
        {
          Sid    = "ReadSecrets"
          Effect = "Allow"

          Action = [
            "secretsmanager:GetSecretValue"
          ]

          Resource = var.secrets_arns
        }
      ] : [],

      length(var.kms_key_arns) > 0 ? [
        {
          Sid    = "DecryptSecrets"
          Effect = "Allow"

          Action = [
            "kms:Decrypt"
          ]

          Resource = var.kms_key_arns
        }
      ] : []
    )
  })
}


# ============================================================
# ECS APPLICATION TASK ROLE
# ============================================================
#
# This role is assumed by the application running inside
# the ECS Fargate containers.
#
# Keep this separate from the ECS execution role.
#

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}


# ============================================================
# ECS APPLICATION PERMISSIONS
# ============================================================

resource "aws_iam_role_policy" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = concat(

      # ------------------------------------------------------
      # Secrets Manager
      # ------------------------------------------------------

      length(var.secrets_arns) > 0 ? [
        {
          Sid    = "ReadApplicationSecrets"
          Effect = "Allow"

          Action = [
            "secretsmanager:GetSecretValue"
          ]

          Resource = var.secrets_arns
        }
      ] : [],

      # ------------------------------------------------------
      # KMS
      # ------------------------------------------------------

      length(var.kms_key_arns) > 0 ? [
        {
          Sid    = "DecryptApplicationSecrets"
          Effect = "Allow"

          Action = [
            "kms:Decrypt"
          ]

          Resource = var.kms_key_arns
        }
      ] : [],

      # ------------------------------------------------------
      # Cloud Map / Service Discovery
      # ------------------------------------------------------

      (
        var.cloud_map_namespace_arn != null ||
        length(var.cloud_map_service_arns) > 0
      ) ? [
        {
          Sid    = "CloudMapServiceDiscovery"
          Effect = "Allow"

          Action = [
            "servicediscovery:GetNamespace",
            "servicediscovery:GetService",
            "servicediscovery:GetInstance",
            "servicediscovery:DiscoverInstances"
          ]

          Resource = compact(
            concat(
              var.cloud_map_namespace_arn != null ? [
                var.cloud_map_namespace_arn
              ] : [],
              var.cloud_map_service_arns
            )
          )
        }
      ] : [],

      # ------------------------------------------------------
      # S3
      # ------------------------------------------------------

      length(var.s3_bucket_arns) > 0 ? [
        {
          Sid    = "ListApplicationBuckets"
          Effect = "Allow"

          Action = [
            "s3:ListBucket"
          ]

          Resource = var.s3_bucket_arns
        },
        {
          Sid    = "ApplicationObjectAccess"
          Effect = "Allow"

          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ]

          Resource = [
            for bucket in var.s3_bucket_arns :
            "${bucket}/*"
          ]
        }
      ] : []
    )
  })
}


# ============================================================
# RDS ENHANCED MONITORING ROLE
# ============================================================

resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_rds_enhanced_monitoring ? 1 : 0

  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}


resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_rds_enhanced_monitoring ? 1 : 0

  role = aws_iam_role.rds_monitoring[0].name

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
