output "secret_arns" {
  description = "Map of logical secret name to its ARN"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_ids" {
  description = "Map of logical secret name to its ID (name)"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "secret_names" {
  description = "Map of logical secret name to its full Secrets Manager name"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

