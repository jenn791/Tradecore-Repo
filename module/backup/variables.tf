variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "kms_key_arn" {
  description = "ARN of the KMS CMK (from the kms module's backup key) used to encrypt the backup vault"
  type        = string
}

variable "schedule_expression" {
  description = "Cron expression (UTC) for when backups run"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "start_window_minutes" {
  description = "Minutes after the scheduled time a backup job can start before it's considered failed"
  type        = number
  default     = 60
}

variable "completion_window_minutes" {
  description = "Minutes a backup job has to complete before it's cancelled"
  type        = number
  default     = 180
}

variable "retention_days" {
  description = "Number of days to retain recovery points before deletion"
  type        = number
  default     = 35
}

variable "cold_storage_after_days" {
  description = "Days before a recovery point transitions to cold storage. Set to null to disable."
  type        = number
  default     = null
}

variable "selection_tag_key" {
  description = "Tag key used to select resources for backup"
  type        = string
  default     = "Backup"
}

variable "selection_tag_value" {
  description = "Tag value used to select resources for backup"
  type        = string
  default     = "true"
}

variable "additional_resource_arns" {
  description = "Explicit resource ARNs to include in the backup selection in addition to tag-based selection"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
