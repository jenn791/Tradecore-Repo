
output "replication_group_id" {
  description = "Redis replication group ID"
  value       = aws_elasticache_replication_group.this.id
}

output "primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Redis reader endpoint"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "Redis security group ID"
  value       = aws_security_group.redis.id
}

output "kms_key_arn" {
  description = "Redis KMS key ARN"
  value       = aws_kms_key.redis.arn
}
