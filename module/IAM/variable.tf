
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "tradecore"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs that ECS tasks are allowed to pull images from"
  type        = list(string)
  default     = []
}

variable "secrets_arns" {
  description = "Secrets Manager ARNs that ECS tasks are allowed to read"
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "KMS key ARNs that ECS tasks can use for decryption"
  type        = list(string)
  default     = []
}

variable "cloud_map_namespace_arn" {
  description = "AWS Cloud Map namespace ARN used for service discovery"
  type        = string
  default     = null
}

variable "cloud_map_service_arns" {
  description = "AWS Cloud Map service ARNs used for service discovery"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs ECS tasks are allowed to access"
  type        = list(string)
  default     = []
}

variable "enable_rds_enhanced_monitoring" {
  description = "Create IAM role for RDS Enhanced Monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to IAM resources where supported"
  type        = map(string)
  default     = {}
}
