
# ---------------------------------------------------------
# KMS
# ---------------------------------------------------------

resource "aws_kms_key" "redis" {
  description             = "TradeCore Africa ElastiCache encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-redis-kms"
    }
  )
}

resource "aws_kms_alias" "redis" {
  name          = "alias/${var.name}-redis"
  target_key_id = aws_kms_key.redis.key_id
}

# ---------------------------------------------------------
# SUBNET GROUP
# ---------------------------------------------------------

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# ---------------------------------------------------------
# SECURITY GROUP
# ---------------------------------------------------------

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Security group for TradeCore ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from application tier"
    from_port       = 6379
    to_port         = 6379
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
      Name = "${var.name}-redis-sg"
    }
  )
}

# ---------------------------------------------------------
# REDIS REPLICATION GROUP
# ---------------------------------------------------------

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name}-redis"

  description = "TradeCore Africa Redis cache"

  engine         = "redis"
  engine_version = var.engine_version

  node_type = var.node_type

  num_cache_clusters = 3

  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name = aws_elasticache_subnet_group.this.name

  security_group_ids = [
    aws_security_group.redis.id
  ]

  port = 6379

  at_rest_encryption_enabled = true
  kms_key_id                  = aws_kms_key.redis.arn

  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  auth_token = var.auth_token

  snapshot_retention_limit = 1
  snapshot_window          = "04:00-05:00"

  maintenance_window = "sun:05:00-sun:06:00"

  auto_minor_version_upgrade = true

  apply_immediately = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-redis"
    }
  )
}
