# TradeCore S3 module variables

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt S3 buckets"
  type        = string
}
