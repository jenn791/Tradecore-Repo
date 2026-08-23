
# =========================================================
# ACM CERTIFICATE
# =========================================================

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-certificate"
    }
  )
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]

  ttl = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    for record in aws_route53_record.certificate_validation :
    record.fqdn
  ]
}

# =========================================================
# ALB SECURITY GROUP
# =========================================================

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for TradeCore Application Load Balancer"
  vpc_id      = var.vpc_id

  # Internal ALB is used by default.
  # The ALB is reached through Global Accelerator.
  ingress {
    description = "HTTPS application traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    description = "Allow outbound traffic to ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb-sg"
    }
  )
}

# =========================================================
# APPLICATION LOAD BALANCER
# =========================================================

resource "aws_lb" "this" {
  name = "${var.name}-alb"

  load_balancer_type = "application"

  internal = var.alb_internal

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = var.alb_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  drop_invalid_header_fields = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb"
    }
  )
}

# =========================================================
# ECS TARGET GROUP
#
# The ECS/Fargate module will attach its services to this
# target group.
# =========================================================

resource "aws_lb_target_group" "ecs" {
  name = "${var.name}-ecs-tg"

  port     = var.application_port
  protocol = "HTTP"

  vpc_id = var.vpc_id

  target_type = "ip"

  deregistration_delay = 30

  health_check {
    enabled = true

    path = var.health_check_path

    protocol = "HTTP"

    port = "traffic-port"

    healthy_threshold   = 3
    unhealthy_threshold = 3

    interval = 30
    timeout  = 5

    matcher = "200-399"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ecs-target-group"
    }
  )
}

# =========================================================
# HTTP LISTENER
# Redirect HTTP → HTTPS
# =========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# =========================================================
# HTTPS LISTENER
# =========================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy = var.ssl_policy

  certificate_arn = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  tags = var.tags
}

# =========================================================
# AWS WAF
# =========================================================

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name}-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # -------------------------------------------------------
  # AWS IP REPUTATION LIST
  # -------------------------------------------------------

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------
  # COMMON AWS MANAGED RULES
  # -------------------------------------------------------

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------
  # SQL INJECTION PROTECTION
  # -------------------------------------------------------

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-sqli"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------
  # RATE LIMITING
  # -------------------------------------------------------

  rule {
    name     = "RateLimit"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-waf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# =========================================================
# WAF → ALB
# =========================================================

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

# =========================================================
# AWS GLOBAL ACCELERATOR
#
# Global Accelerator is a global service. The provider alias
# aws.global is configured in the root module.
# =========================================================

resource "aws_globalaccelerator_accelerator" "this" {
  provider = aws.global

  name = "${var.name}-accelerator"

  enabled = true

  ip_address_type = "IPV4"

  attributes {
    flow_logs_enabled = false
  }

  tags = var.tags
}

# =========================================================
# GLOBAL ACCELERATOR LISTENER
# =========================================================

resource "aws_globalaccelerator_listener" "https" {
  provider = aws.global

  accelerator_arn = aws_globalaccelerator_accelerator.this.id

  protocol = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }

  client_affinity = "NONE"
}

# =========================================================
# GLOBAL ACCELERATOR ENDPOINT GROUP
# =========================================================

resource "aws_globalaccelerator_endpoint_group" "this" {
  provider = aws.global

  listener_arn = aws_globalaccelerator_listener.https.id

  endpoint_group_region = var.aws_region

  health_check_protocol = "HTTPS"
  health_check_port     = 443
  health_check_path      = var.health_check_path

  health_check_interval_seconds = 30
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id = aws_lb.this.arn

    weight = 100

    client_ip_preservation_enabled = true
  }
}

# =========================================================
# ROUTE 53 → GLOBAL ACCELERATOR
# =========================================================

resource "aws_route53_record" "application" {
  zone_id = var.route53_zone_id

  name = var.domain_name
  type = "A"

  alias {
    name                   = aws_globalaccelerator_accelerator.this.dns_name
    zone_id                = aws_globalaccelerator_accelerator.this.hosted_zone_id
    evaluate_target_health = false
  }
}
