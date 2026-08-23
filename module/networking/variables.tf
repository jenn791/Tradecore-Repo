# Variables required for Networking
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "TradeCore VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the VPC"
  type        = list(string)
}
