
output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "writer_endpoint" {
  description = "Aurora writer endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Aurora PostgreSQL port"
  value       = aws_rds_cluster.this.port
}

output "rds_security_group_id" {
  description = "Aurora security group ID"
  value       = aws_security_group.rds.id
}

output "proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = aws_db_proxy.this.endpoint
}

output "proxy_arn" {
  description = "RDS Proxy ARN"
  value       = aws_db_proxy.this.arn
}

output "proxy_security_group_id" {
  description = "RDS Proxy security group ID"
  value       = aws_security_group.rds_proxy.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing the Aurora master credentials"
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "RDS KMS key ARN"
  value       = aws_kms_key.rds.arn
}
