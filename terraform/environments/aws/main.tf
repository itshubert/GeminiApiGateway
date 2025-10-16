# AWS Production Environment

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend for state storage
  backend "s3" {
    bucket         = "gemini-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "gemini-terraform-locks"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Networking
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}

# Service Discovery
module "service_discovery" {
  source = "../../modules/service-discovery"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  tags         = var.tags
}

# ECS Cluster
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.ecs_cluster_name
  tags         = var.tags
}

# ECR Repositories
module "ecr" {
  source = "../../modules/ecr"

  project_name        = var.project_name
  environment         = var.environment
  repository_prefix   = var.ecr_repository_prefix
  tags                = var.tags
}

# Catalog Service
module "catalog_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "catalog"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["catalog"]}:${var.catalog_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                                     = "Production"
    ASPNETCORE_URLS                                           = "http://+:80"
    ConnectionStrings__GeminiCatalogDbContext                 = var.catalog_db_connection
    AWS__UseLocalStack                                        = "false"
    AWS__Region                                               = var.aws_region
  }

  tags = var.tags
}

# Customer Service
module "customer_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "customer"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["customer"]}:${var.customer_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                                     = "Production"
    ASPNETCORE_URLS                                           = "http://+:80"
    ConnectionStrings__GeminiCustomerDbContext                = var.customer_db_connection
    AWS__UseLocalStack                                        = "false"
    AWS__Region                                               = var.aws_region
  }

  tags = var.tags
}

# Inventory Service
module "inventory_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "inventory"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["inventory"]}:${var.inventory_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                                     = "Production"
    ASPNETCORE_URLS                                           = "http://+:80"
    ConnectionStrings__GeminiInventoryDbContext               = var.inventory_db_connection
    AWS__UseLocalStack                                        = "false"
    AWS__Region                                               = var.aws_region
  }

  tags = var.tags
}

# Order Service
module "order_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "order"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["order"]}:${var.order_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                                     = "Production"
    ASPNETCORE_URLS                                           = "http://+:80"
    ConnectionStrings__GeminiOrderDbContext                   = var.order_db_connection
    AWS__UseLocalStack                                        = "false"
    AWS__Region                                               = var.aws_region
  }

  tags = var.tags
}

# Order Fulfillment Service
module "orderfulfillment_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "orderfulfillment"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["orderfulfillment"]}:${var.orderfulfillment_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                                     = "Production"
    ASPNETCORE_URLS                                           = "http://+:80"
    ConnectionStrings__GeminiOrderFulfillmentDbContext        = var.orderfulfillment_db_connection
    AWS__UseLocalStack                                        = "false"
    AWS__Region                                               = var.aws_region
  }

  tags = var.tags
}

# Warehouse Service
module "warehouse_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "warehouse"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["warehouse"]}:${var.warehouse_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                                     = "Production"
    ASPNETCORE_URLS                                           = "http://+:80"
    ConnectionStrings__GeminiWarehouseDbContext               = var.warehouse_db_connection
    AWS__UseLocalStack                                        = "false"
    AWS__Region                                               = var.aws_region
  }

  tags = var.tags
}

# API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name     = var.project_name
  environment      = var.environment
  api_name         = "gemini-api"
  alb_listener_arn = module.networking.alb_listener_arn
  alb_dns_name     = module.networking.alb_dns_name
  stage_name       = "v1"

  tags = var.tags
}
