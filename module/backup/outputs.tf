output "vault_tradecore" {
  description = "Name/ID of the backup vault"
  value       = aws_backup_vault.this.id
}

output "vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.this.arn
}

output "plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.this.id
}

output "plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.this.arn
}

output "plan_version" {
  description = "Version identifier of the backup plan (changes whenever the plan is updated)"
  value       = aws_backup_plan.this.version
}

output "backup_role_arn" {
  description = "ARN of the IAM role AWS Backup assumes to take and restore snapshots"
  value       = aws_iam_role.backup.arn
}

output "selection_id" {
  description = "ID of the backup selection"
  value       = aws_backup_selection.this.id
}

