locals { 
  common_tags = merge(var.tags, { 
    Environment = var.environment 
    ManagedBy   = "terraform" 
    Module      = "security-groups" 
  }) 
} 
 
# --------------------------------------------------------------------------- 
# Frontend tier - public subnets 
# No ALB in this architecture: Route 53 -> Global Accelerator -> WAF sit in 
# front, then traffic reaches these tasks directly. This SG is therefore the 
# actual internet-facing boundary, not just an internal rule - restrict 
# frontend_ingress_cidrs in production. 
# --------------------------------------------------------------------------- 
resource "aws_security_group" "frontend" { 
  name_prefix = "tradecore-${var.environment}-frontend-" 
  description = "Tradecore frontend (public subnet) - internet-facing, behind GA/WAF" 
  vpc_id      = var.vpc_id 
 
  ingress { 
    description = "App traffic from allowed sources (GA/WAF edge)" 
    from_port   = var.frontend_port 
    to_port     = var.frontend_port 
    protocol    = "tcp" 
    cidr_blocks = var.frontend_ingress_cidrs 
  } 
 
  egress { 
    description = "To ECS backend/API tasks and out via NAT" 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  tags = merge(local.common_tags, { 
    Name = "tradecore-${var.environment}-frontend-sg" 
  }) 
 
  lifecycle { 
    create_before_destroy = true 
  } 
} 
 
# --------------------------------------------------------------------------- 
# ECS backend/API tier - private subnets, Active-Active across 3 AZs 
# Reachable only from the frontend tier, plus itself for Cloud Map 
# service-to-service traffic between tasks in different AZs. 
# --------------------------------------------------------------------------- 
resource "aws_security_group" "ecs" { 
  name_prefix = "tradecore-${var.environment}-ecs-" 
  description = "Tradecore ECS Fargate backend/API tasks - traffic from frontend and peer tasks only" 
  vpc_id      = var.vpc_id 
 
  ingress { 
    description     = "API traffic from frontend tasks" 
    from_port       = var.ecs_backend_port 
    to_port         = var.ecs_backend_port 
    protocol        = "tcp" 
    security_groups = [aws_security_group.frontend.id] 
  } 
 
  egress { 
    description = "To RDS Proxy, Redis, VPC endpoints, and out via NAT" 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  tags = merge(local.common_tags, { 
    Name = "tradecore-${var.environment}-ecs-sg" 
  }) 
 
  lifecycle { 
    create_before_destroy = true 
  } 
} 
 
# Self-referencing rule for direct service-to-service calls via Cloud Map 
# (separate from the frontend->backend path above). 
resource "aws_security_group_rule" "ecs_service_mesh" { 
  for_each = var.enable_service_mesh_ingress ? toset([for p in var.ecs_service_mesh_ports : tostring(p)]) : [] 
 
  type              = "ingress" 
  from_port         = tonumber(each.value) 
  to_port           = tonumber(each.value) 
  protocol          = "tcp" 
  security_group_id = aws_security_group.ecs.id 
  self              = true 
  description       = "Inter-service traffic via Cloud Map on port ${each.value}" 
} 
 
# --------------------------------------------------------------------------- 
# RDS Proxy - sits between ECS and Aurora for connection pooling/failover. 
# Reachable only from ECS; itself is the only thing allowed to reach Aurora. 
# --------------------------------------------------------------------------- 
resource "aws_security_group" "rds_proxy" { 
  name_prefix = "tradecore-${var.environment}-rds-proxy-" 
  description = "Tradecore RDS Proxy - traffic from ECS only, proxies to Aurora" 
  vpc_id      = var.vpc_id 
 
  ingress { 
    description     = "PostgreSQL from ECS tasks" 
    from_port       = var.rds_proxy_port 
    to_port         = var.rds_proxy_port 
    protocol        = "tcp" 
    security_groups = [aws_security_group.ecs.id] 
  } 
 
  egress { 
    description = "To Aurora" 
    from_port   = var.aurora_port 
    to_port     = var.aurora_port 
    protocol    = "tcp" 
    cidr_blocks = [var.vpc_cidr] 
  } 
 
  tags = merge(local.common_tags, { 
    Name = "tradecore-${var.environment}-rds-proxy-sg" 
  }) 
 
  lifecycle { 
    create_before_destroy = true 
  } 
} 
 
# --------------------------------------------------------------------------- 
# Aurora PostgreSQL (writer + 2 readers, Multi-AZ) - reachable only from the 
# RDS Proxy. ECS never talks to Aurora directly in this design. 
# --------------------------------------------------------------------------- 
resource "aws_security_group" "aurora" { 
  name_prefix = "tradecore-${var.environment}-aurora-" 
  description = "Tradecore Aurora PostgreSQL - traffic from RDS Proxy only" 
  vpc_id      = var.vpc_id 
 
  ingress { 
    description     = "PostgreSQL from RDS Proxy" 
    from_port       = var.aurora_port 
    to_port         = var.aurora_port 
    protocol        = "tcp" 
    security_groups = [aws_security_group.rds_proxy.id] 
  }

    egress {
    description = "Return traffic within the VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
 
  tags = merge(local.common_tags, { 
    Name = "tradecore-${var.environment}-aurora-sg" 
  }) 
 
  lifecycle { 
    create_before_destroy = true 
  } 
} 
 
# --------------------------------------------------------------------------- 
# ElastiCache Redis (one node per AZ, co-located with each Aurora reader) - 
# reachable only from ECS tasks. 
# --------------------------------------------------------------------------- 
resource "aws_security_group" "redis" { 
  name_prefix = "tradecore-${var.environment}-redis-" 
  description = "Tradecore ElastiCache Redis - traffic from ECS only" 
  vpc_id      = var.vpc_id 
 
  ingress { 
    description     = "Redis from ECS tasks" 
    from_port       = var.redis_port 
    to_port         = var.redis_port 
    protocol        = "tcp" 
    security_groups = [aws_security_group.ecs.id] 
  } 
 
  tags = merge(local.common_tags, { 
    Name = "tradecore-${var.environment}-redis-sg" 
  }) 
 
  lifecycle { 
    create_before_destroy = true 
  } 
} 
 
# --------------------------------------------------------------------------- 
# Interface VPC endpoints (Secrets Manager, KMS, ECR, CloudWatch Logs, etc.) 
# Lets ECS/RDS Proxy reach these AWS APIs without traversing the NAT Gateway, 
# keeping that traffic inside af-south-1 rather than routing out to a public 
# service endpoint. 
# --------------------------------------------------------------------------- 
resource "aws_security_group" "vpc_endpoints" { 
  count = var.enable_vpc_endpoints_sg ? 1 : 0 
 
  name_prefix = "tradecore-${var.environment}-vpce-" 
  description = "Tradecore interface VPC endpoints - HTTPS from ECS and RDS Proxy" 
  vpc_id      = var.vpc_id 
 
  ingress { 
    description     = "HTTPS from ECS tasks" 
    from_port       = 443 
    to_port         = 443 
    protocol        = "tcp" 
    security_groups = [aws_security_group.ecs.id] 
  } 
 
  ingress { 
    description     = "HTTPS from RDS Proxy (IAM auth to Secrets Manager/KMS)" 
    from_port       = 443 
    to_port         = 443 
    protocol        = "tcp" 
    security_groups = [aws_security_group.rds_proxy.id] 
  } 
 
  tags = merge(local.common_tags, { 
    Name = "tradecore-${var.environment}-vpce-sg" 
  }) 
 
  lifecycle { 
    create_before_destroy = true 
  } 
} 
