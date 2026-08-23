variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "my-ecs-cluster"
}

variable "container_insights_enabled" {
  description = "Whether to enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "my-ecs-service"
}

variable "container_name" {
  description = "Name of the container in the task definition"
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Container image to run (e.g. repo/image:tag)"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Map of environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (e.g. 256, 512, 1024)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task (e.g. 512, 1024, 2048)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of running tasks for the service"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "VPC ID where the ECS service and security group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service network configuration"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the ECS tasks (needed for public subnets without a NAT gateway)"
  type        = bool
  default     = false
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the container port"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_group_arn" {
  description = "ARN of an existing ALB/NLB target group to attach the service to. Leave empty to skip load balancer integration."
  type        = string
  default     = ""
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployments"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum percent during deployments"
  type        = number
  default     = 200
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

