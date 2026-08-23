
variable "name" {
  description = "Environment/application name"
  type        = string
}

variable "aws_region" {
  description = "AWS application region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_subnet_ids" {
  description = "Subnets where the ALB will be deployed"
  type        = list(string)

  validation {
    condition     = length(var.alb_subnet_ids) >= 2
    error_message = "At least two subnets are required for the ALB."
  }
}

variable "alb_internal" {
  description = "Whether the ALB should be internal"
  type        = bool
  default     = true
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB"
  type        = list(string)

  default = [
    "0.0.0.0/0"
  ]
}

variable "application_port" {
  description = "Port exposed by the ECS application"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Application health check path"
  type        = string
  default     = "/health"
}

variable "domain_name" {
  description = "Application DNS name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5-minute period per IP"
  type        = number
  default     = 2000
}

variable "ssl_policy" {
  description = "ALB SSL policy"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "Protect the ALB from accidental deletion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
