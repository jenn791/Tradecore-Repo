variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_id" {
  description = "ID of the Tradecore VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the Tradecore VPC, used for intra-VPC rules"
  type        = string
}

# --- Frontend tier (public subnets, no ALB) ---
# Per the architecture diagram, the ALB was removed - Global Accelerator and
# WAF sit in front, and traffic reaches the frontend tasks directly (e.g. via
# an NLB target group in IP mode, which passes the original client through
# rather than terminating it like an ALB does). That means this security
# group - not an ALB SG - is the actual internet-facing boundary.
variable "frontend_port" {
  description = "Port the frontend (static/web) tasks listen on"
  type        = number
  default     = 443
}

variable "frontend_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the frontend tasks directly. Since there is no ALB in front of them, tighten this to Global Accelerator's published edge ranges where possible rather than leaving it world-open."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- ECS backend / API tier (private subnets) ---
variable "ecs_backend_port" {
  description = "Port the ECS Fargate backend/API tasks listen on"
  type        = number
  default     = 3000
}

variable "enable_service_mesh_ingress" {
  description = "Whether to allow ECS tasks to talk to each other directly on ecs_service_mesh_ports (needed for Cloud Map / Service Connect service-to-service calls beyond the frontend->backend path)"
  type        = bool
  default     = true
}

variable "ecs_service_mesh_ports" {
  description = "Additional ports ECS tasks need to reach each other on for service discovery / inter-service calls via Cloud Map"
  type        = list(number)
  default     = [3000]
}

# --- Data tier ---
variable "rds_proxy_port" {
  description = "Port the RDS Proxy listens on"
  type        = number
  default     = 5432
}

variable "aurora_port" {
  description = "Port Aurora PostgreSQL listens on"
  type        = number
  default     = 5432
}

variable "redis_port" {
  description = "Port ElastiCache Redis listens on"
  type        = number
  default     = 6379
}

# --- VPC interface endpoints ---
variable "enable_vpc_endpoints_sg" {
  description = "Whether to create a security group for interface VPC endpoints (Secrets Manager, KMS, ECR, CloudWatch Logs, etc.)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all security groups in this module"
  type        = map(string)
  default     = {}
}

