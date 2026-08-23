variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project/prefix name used in resource naming"
  type        = string
  default     = "myproject"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Log Group
variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = "/myproject/app"
}

variable "log_retention_days" {
  description = "Number of days to retain logs (0 = never expire). Valid values: 1,3,5,7,14,30,60,90,120,150,180,365,400,545,731,1096,1827,2192,2557,2922,3288,3653,0"
  type        = number
  default     = 14
}

variable "kms_key_id" {
  description = "Optional KMS key ARN to encrypt log data at rest. Leave empty to use default encryption."
  type        = string
  default     = ""
}

# SNS (Alarm Notifications)
variable "create_sns_topic" {
  description = "Whether to create a new SNS topic for alarm notifications"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address to subscribe to the SNS alert topic (leave empty to skip email subscription)"
  type        = string
  default     = ""
}

variable "existing_sns_topic_arns" {
  description = "List of existing SNS topic ARNs to notify instead of creating a new one (used when create_sns_topic = false)"
  type        = list(string)
  default     = []
}

# Metric Alarms
variable "alarms" {
  description = "Map of CloudWatch metric alarms to create. Key is a short alarm identifier."
  type = map(object({
    description         = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    treat_missing_data  = string
    dimensions          = map(string)
  }))

  default = {
    high_cpu = {
      description         = "Triggers when average CPU exceeds threshold"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      treat_missing_data  = "missing"
      dimensions          = {}
    }
  }
}

# Log Metric Filters
variable "log_metric_filters" {
  description = "Map of log metric filters to create from the log group. Key is the filter name."
  type = map(object({
    pattern           = string
    metric_name       = string
    metric_namespace  = string
    metric_value      = string
    default_value     = string
  }))
  default = {}
}

# Dashboard
variable "create_dashboard" {
  description = "Whether to create a CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "dashboard_metrics" {
  description = "List of metric definitions to display on the dashboard (in CloudWatch metrics widget format)"
  type        = list(any)
  default = [
    ["AWS/ECS", "CPUUtilization"]
  ]
}

