variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Trail
variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "myproject-trail"
}

variable "is_multi_region_trail" {
  description = "Whether the trail logs events from all regions, not just the region it's created in (recommended: true)"
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Whether this is an AWS Organizations trail that logs events for all accounts in the org (requires org management account and organization access enabled)"
  type        = bool
  default     = false
}

variable "include_global_service_events" {
  description = "Whether to include events from global services like IAM and STS"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Whether to enable log file integrity validation (adds digest files to detect tampering)"
  type        = bool
  default     = true
}

variable "event_selectors" {
  description = "Event selectors controlling which events are logged (management, data events like S3 object-level or Lambda invocations)"
  type = list(object({
    read_write_type           = string
    include_management_events = bool
    data_resources = list(object({
      type   = string
      values = list(string)
    }))
  }))

  default = [
    {
      read_write_type           = "All"
      include_management_events = true
      data_resources             = []
    }
  ]
}

# S3 Bucket (log storage)
variable "trail_bucket_name" {
  description = "Globally unique S3 bucket name to store CloudTrail logs"
  type        = string
  default     = "myproject-cloudtrail-logs-change-me"
}

variable "s3_key_prefix" {
  description = "Optional S3 key prefix for log files (leave empty for none)"
  type        = string
  default     = ""
}

variable "force_destroy_bucket" {
  description = "Whether to allow Terraform to delete the bucket even if it still contains log files (use with caution)"
  type        = bool
  default     = false
}

variable "log_expiration_days" {
  description = "Number of days after which log files are automatically deleted (0 = keep forever)"
  type        = number
  default     = 365
}

# Encryption
variable "kms_key_arn" {
  description = "Optional KMS key ARN to encrypt trail logs (S3 + CloudTrail). Leave empty to use default AES256 S3 encryption."
  type        = string
  default     = ""
}

# CloudWatch Logs Integration
variable "enable_cloudwatch_logs" {
  description = "Whether to also deliver CloudTrail events to a CloudWatch Logs group for near-real-time querying/alerting"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudTrail events in CloudWatch Logs"
  type        = number
  default     = 90
}

# SNS Notifications
variable "enable_sns_notifications" {
  description = "Whether to create an SNS topic that CloudTrail publishes to on each new log file delivery"
  type        = bool
  default     = false
}

variable "notification_email" {
  description = "Email address to subscribe to the SNS notification topic (leave empty to skip email subscription)"
  type        = string
  default     = ""
}

