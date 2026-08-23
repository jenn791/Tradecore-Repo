
output "accelerator_dns_name" {
  description = "Global Accelerator DNS name"
  value       = aws_globalaccelerator_accelerator.this.dns_name
}

output "accelerator_arn" {
  description = "Global Accelerator ARN"
  value       = aws_globalaccelerator_accelerator.this.arn
}

output "accelerator_ip_addresses" {
  description = "Static Global Accelerator IP addresses"
  value       = aws_globalaccelerator_accelerator.this.ip_sets[0].ip_addresses
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ECS target group ARN"
  value       = aws_lb_target_group.ecs.arn
}

output "https_listener_arn" {
  description = "ALB HTTPS listener ARN"
  value       = aws_lb_listener.https.arn
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.this.arn
}

output "waf_arn" {
  description = "AWS WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "application_url" {
  description = "Application HTTPS URL"
  value       = "https://${var.domain_name}"
}
