# ALB Security Group
module "alb_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules = ["all-all"]

  tags = {
    Environment = var.environment
  }
}

# RDS Security Group
module "rds_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.eks.node_security_group_id
    }
  ]

  tags = {
    Environment = var.environment
  }
}

# Redis Security Group
module "redis_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      source_security_group_id = module.eks.node_security_group_id
    }
  ]

  tags = {
    Environment = var.environment
  }
}

# Additional EKS Node Group Security Group Rules
resource "aws_security_group_rule" "node_group_ingress_cluster_443" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_group_ingress_cluster_kubelet" {
  description              = "Allow cluster control plane to receive communication from worker Kubelets"
  from_port                = 10250
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
  to_port                  = 10250
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_group_ingress_self" {
  description       = "Allow node to communicate with each other"
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  self              = true
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "node_group_ingress_cluster_primary" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
  to_port                  = 443
  type                     = "ingress"
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = module.redis.cluster_address
}