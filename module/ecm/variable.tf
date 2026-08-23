
variable "name" {
  description = "Environment/application name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Redis"
  type        = list(string)
}

variable "application_security_group_id" {
  description = "Security group ID used by ECS application tasks"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r7g.large"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.2"
}

variable "auth_token" {
  description = "Optional Redis AUTH token"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
