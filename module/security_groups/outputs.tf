# SG output
output "frontend_security_group_id" {
  description = "ID of the frontend (public subnet) security group"
  value       = aws_security_group.frontend.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS backend/API tasks security group"
  value       = aws_security_group.ecs.id
}

output "rds_proxy_security_group_id" {
  description = "ID of the RDS Proxy security group"
  value       = aws_security_group.rds_proxy.id
}

output "aurora_security_group_id" {
  description = "ID of the Aurora PostgreSQL security group"
  value       = aws_security_group.aurora.id
}

output "redis_security_group_id" {
  description = "ID of the ElastiCache Redis security group"
  value       = aws_security_group.redis.id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the interface VPC endpoints security group, if created"
  value       = var.enable_vpc_endpoints_sg ? aws_security_group.vpc_endpoints[0].id : null
}

