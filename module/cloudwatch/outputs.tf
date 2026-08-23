output "log_group_name" {
  description = "tradecore-cloudwatch"
  value       = aws_cloudwatch_log_group.tradecore-cloudwatch
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications (if created)"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : null
}

output "alarm_arns" {
  description = "Map of created CloudWatch alarm names to their ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard (if created)"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.this[0].dashboard_arn : null
}

