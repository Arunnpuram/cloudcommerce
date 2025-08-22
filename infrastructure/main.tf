terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  backend "s3" {
    bucket = "cloudcommerce-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "cloudcommerce"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      name = "main-node-group"
      
      instance_types = ["t3.medium"]
      
      min_size     = 2
      max_size     = 10
      desired_size = 3

      disk_size = 50
      ami_type  = "AL2_x86_64"
      
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      taints = []

      update_config = {
        max_unavailable_percentage = 33
      }
    }

    spot = {
      name = "spot-node-group"
      
      instance_types = ["t3.medium", "t3a.medium", "t2.medium"]
      capacity_type  = "SPOT"
      
      min_size     = 0
      max_size     = 5
      desired_size = 2

      labels = {
        Environment = var.environment
        NodeGroup   = "spot"
      }

      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = {
    Environment = var.environment
  }
}

# RDS PostgreSQL for Product Service
module "rds" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project_name}-postgres"

  engine            = "postgres"
  engine_version    = "14.9"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "cloudcommerce_products"
  username = "cloudcommerce"
  password = random_password.rds_password.result
  port     = "5432"

  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  subnet_group_name = module.vpc.database_subnet_group
  family = "postgres14"

  tags = {
    Environment = var.environment
  }
}

# ElastiCache Redis for Order Service
module "redis" {
  source = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"

  cluster_id           = "${var.project_name}-redis"
  description          = "Redis cluster for CloudCommerce"

  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_nodes = 1
  
  subnet_group_name = module.vpc.elasticache_subnet_group_name
  security_group_ids = [module.redis_security_group.security_group_id]

  tags = {
    Environment = var.environment
  }
}

# Application Load Balancer
module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${var.project_name}-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "tg-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        unhealthy_threshold = 2
      }
    }
  ]

  tags = {
    Environment = var.environment
  }
}