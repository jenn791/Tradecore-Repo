output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task IAM role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS application task IAM role"
  value       = aws_iam_role.ecs_task.name
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS Enhanced Monitoring IAM role"
  value = var.enable_rds_enhanced_monitoring ? aws_iam_role.rds_monitoring[0].arn : null
}
