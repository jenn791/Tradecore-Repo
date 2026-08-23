# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "tradecore-cloudwatch" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id != "" ? var.kms_key_id : null

  tags = var.tags
}

# SNS Topic for Alarm Notifications
resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-cloudwatch-alerts"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns_topic && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Metric Alarm(s)
resource "aws_cloudwatch_metric_alarm" "tardecore-alarm" {
  for_each = var.alarms

  alarm_name          = "${var.project_name}-${each.key}"
  alarm_description   = each.value.description
  comparison_operator = each.value.comparison_operator
  evaluation_periods   = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data

  dimensions = each.value.dimensions

  alarm_actions = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : var.existing_sns_topic_arns
  ok_actions    = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : var.existing_sns_topic_arns

  tags = var.tags
}

# CloudWatch Log Metric Filter (optional)
resource "aws_cloudwatch_log_metric_filter" "tradecore-filter" {
  for_each = var.log_metric_filters

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.value.metric_name
    namespace     = each.value.metric_namespace
    value         = each.value.metric_value
    default_value = each.value.default_value
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "tradecore-dashboard" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Widget - ${var.project_name}"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = var.dashboard_metrics
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          title  = "Recent Logs - ${var.log_group_name}"
          region = var.aws_region
          query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          view   = "table"
        }
      }
    ]
  })
}

