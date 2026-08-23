# Tradecore KMS outputs

output "tradecore_key_id" {
  description = "Key ID of the main Tradecore CMK"
  value       = aws_kms_key.tradecore.key_id
}

output "tradecore_key_arn" {
  description = "ARN of the main Tradecore CMK"
  value       = aws_kms_key.tradecore.arn
}

output "tradecore_alias_arn" {
  description = "ARN of the main Tradecore CMK alias"
  value       = aws_kms_alias.tradecore.arn
}

output "s3_key_id" {
  description = "Key ID of the S3 encryption CMK"
  value       = aws_kms_key.s3.key_id
}

output "s3_key_arn" {
  description = "ARN of the S3 encryption CMK"
  value       = aws_kms_key.s3.arn
}

output "s3_alias_arn" {
  description = "ARN of the S3 encryption CMK alias"
  value       = aws_kms_alias.s3.arn
}

output "rds_key_id" {
  description = "Key ID of the RDS/Aurora encryption CMK"
  value       = aws_kms_key.rds.key_id
}

output "rds_key_arn" {
  description = "ARN of the RDS/Aurora encryption CMK"
  value       = aws_kms_key.rds.arn
}

output "rds_alias_arn" {
  description = "ARN of the RDS/Aurora encryption CMK alias"
  value       = aws_kms_alias.rds.arn
}

output "backup_key_id" {
  description = "Key ID of the backup vault encryption CMK"
  value       = aws_kms_key.backup.key_id
}

output "backup_key_arn" {
  description = "ARN of the backup vault encryption CMK"
  value       = aws_kms_key.backup.arn
}

output "backup_alias_arn" {
  description = "ARN of the backup vault encryption CMK alias"
  value       = aws_kms_alias.backup.arn
}

output "secrets_key_id" {
  description = "Key ID of the Secrets Manager encryption CMK"
  value       = aws_kms_key.secrets.key_id
}

output "secrets_key_arn" {
  description = "ARN of the Secrets Manager encryption CMK"
  value       = aws_kms_key.secrets.arn
}

output "secrets_alias_arn" {
  description = "ARN of the Secrets Manager encryption CMK alias"
  value       = aws_kms_alias.secrets.arn
}
