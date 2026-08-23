data "aws_caller_identity" "current" {}

# ---------------------------------------------------------
# KMS
# ---------------------------------------------------------

resource "aws_kms_key" "rds" {
  description             = "TradeCore Africa RDS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-kms"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ---------------------------------------------------------
# RDS SUBNET GROUP
# ---------------------------------------------------------

resource "aws_db_subnet_group" "rds" {
  name       = "${var.name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-subnet-group"
    }
  )
}

# ---------------------------------------------------------
# SECURITY GROUP
# ---------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for TradeCore Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from application tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.application_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-sg"
    }
  )
}

# ---------------------------------------------------------
# CLUSTER PARAMETER GROUP
# ---------------------------------------------------------

resource "aws_rds_cluster_parameter_group" "postgresql" {
  name        = "${var.name}-aurora-postgresql"
  family      = var.cluster_parameter_group_family
  description = "TradeCore Aurora PostgreSQL cluster parameters"

  tags = var.tags
}

# ---------------------------------------------------------
# INSTANCE PARAMETER GROUP
# ---------------------------------------------------------

resource "aws_db_parameter_group" "postgresql" {
  name        = "${var.name}-aurora-postgresql-instance"
  family      = var.instance_parameter_group_family
  description = "TradeCore Aurora PostgreSQL instance parameters"

  tags = var.tags
}

# ---------------------------------------------------------
# AURORA CLUSTER
# ---------------------------------------------------------

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.name}-aurora"

  engine         = "aurora-postgresql"
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.master_username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.key_id

  db_subnet_group_name = aws_db_subnet_group.rds.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql.name

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  iam_database_authentication_enabled = true

  backup_retention_period = var.backup_retention_period

  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "iam-db-auth-error"
  ]

  deletion_protection = var.deletion_protection

  skip_final_snapshot = false

  final_snapshot_identifier = "${var.name}-final-snapshot"

  copy_tags_to_snapshot = true

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  db_cluster_instance_class = var.instance_class

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-aurora-cluster"
    }
  )
}

# ---------------------------------------------------------
# AURORA INSTANCES
#
# Instance 0 = writer
# Instance 1 = reader
# Instance 2 = reader
# ---------------------------------------------------------

resource "aws_rds_cluster_instance" "this" {
  count = 3

  identifier = "${var.name}-aurora-${count.index + 1}"

  cluster_identifier = aws_rds_cluster.this.id

  instance_class = var.instance_class
  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  availability_zone = var.availability_zones[count.index]

  db_subnet_group_name = aws_db_subnet_group.rds.name

  db_parameter_group_name = aws_db_parameter_group.postgresql.name

  promotion_tier = count.index == 0 ? 0 : 1

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-aurora-${count.index + 1}"
    }
  )
}

# ---------------------------------------------------------
# RDS PROXY IAM ROLE
# ---------------------------------------------------------

resource "aws_iam_role" "rds_proxy" {
  name = "${var.name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "rds.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# ---------------------------------------------------------
# RDS PROXY IAM POLICY
# ---------------------------------------------------------

resource "aws_iam_role_policy" "rds_proxy" {
  name = "${var.name}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_rds_cluster.this.master_user_secret[0].secret_arn
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = aws_kms_key.rds.arn
      }
    ]
  })
}

# ---------------------------------------------------------
# RDS PROXY SECURITY GROUP
# ---------------------------------------------------------

resource "aws_security_group" "rds_proxy" {
  name        = "${var.name}-rds-proxy-sg"
  description = "Security group for TradeCore RDS Proxy"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from application tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.application_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-proxy-sg"
    }
  )
}

# ---------------------------------------------------------
# RDS PROXY
# ---------------------------------------------------------

resource "aws_db_proxy" "this" {
  name = "${var.name}-rds-proxy"

  debug_logging = false

  engine_family = "POSTGRESQL"

  require_tls = true

  role_arn = aws_iam_role.rds_proxy.arn

  vpc_security_group_ids = [
    aws_security_group.rds_proxy.id
  ]

  vpc_subnet_ids = var.private_subnet_ids

  default_auth_scheme = "NONE"

  auth {
    auth_scheme = "SECRETS"

    iam_auth = "REQUIRED"

    secret_arn = aws_rds_cluster.this.master_user_secret[0].secret_arn
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-proxy"
    }
  )
}

# ---------------------------------------------------------
# RDS PROXY DEFAULT TARGET GROUP
# ---------------------------------------------------------

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 90
    max_idle_connections_percent = 50
  }

  lifecycle {
    replace_triggered_by = [
      aws_db_proxy.this.id
    ]
  }
}

# ---------------------------------------------------------
# RDS PROXY TARGET
# ---------------------------------------------------------

resource "aws_db_proxy_target" "this" {
  db_proxy_name = aws_db_proxy.this.name

  target_group_name = aws_db_proxy_default_target_group.this.name

  db_cluster_identifier = aws_rds_cluster.this.cluster_identifier

  lifecycle {
    replace_triggered_by = [
      aws_db_proxy.this.id
    ]
  }
}
