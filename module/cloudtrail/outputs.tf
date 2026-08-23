output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.this.arn
}

output "trail_home_region" {
  description = "The home region of the trail"
  value       = aws_cloudtrail.this.home_region
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.trail.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.trail.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group receiving trail events (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.trail[0].name : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for log delivery notifications (if enabled)"
  value       = var.enable_sns_notifications ? aws_sns_topic.trail_notifications[0].arn : null
}

