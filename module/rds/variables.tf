
variable "name" {
  description = "Environment/application name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Aurora and RDS Proxy"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability Zones for Aurora instances"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly three Availability Zones are required."
  }
}

variable "application_security_group_id" {
  description = "Security group ID used by the ECS application tier"
  type        = string
}

variable "database_name" {
  description = "Aurora database name"
  type        = string
  default     = "tradecore"
}

variable "master_username" {
  description = "Aurora master username"
  type        = string
  default     = "tradecore_admin"
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.6"
}

variable "cluster_parameter_group_family" {
  description = "Aurora PostgreSQL cluster parameter family"
  type        = string
  default     = "aurora-postgresql16"
}

variable "instance_parameter_group_family" {
  description = "Aurora PostgreSQL instance parameter family"
  type        = string
  default     = "aurora-postgresql16"
}

variable "instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental database deletion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
