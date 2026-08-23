# Tradecore S3 outputs

output "app_data_bucket_id" {
  description = "Name/ID of the application data bucket"
  value       = aws_s3_bucket.app_data.id
}

output "app_data_bucket_arn" {
  description = "ARN of the application data bucket"
  value       = aws_s3_bucket.app_data.arn
}

output "app_data_bucket_domain_name" {
  description = "Regional domain name of the application data bucket"
  value       = aws_s3_bucket.app_data.bucket_regional_domain_name
}

output "access_logs_bucket_id" {
  description = "Name/ID of the access logs bucket"
  value       = aws_s3_bucket.access_logs.id
}

output "access_logs_bucket_arn" {
  description = "ARN of the access logs bucket"
  value       = aws_s3_bucket.access_logs.arn
}

output "access_logs_bucket_domain_name" {
  description = "Regional domain name of the access logs bucket"
  value       = aws_s3_bucket.access_logs.bucket_regional_domain_name
}

