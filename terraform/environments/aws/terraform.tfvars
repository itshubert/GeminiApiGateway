# AWS Production Environment Variables

environment    = "prod"
aws_region     = "us-east-1"
project_name   = "gemini"
use_localstack = false

# Certificate password (use AWS Secrets Manager in production)
certificate_password = "REPLACE_WITH_SECURE_PASSWORD"

# Database Connection Strings (use AWS Secrets Manager or SSM Parameter Store)
catalog_db_connection        = "REPLACE_WITH_RDS_CONNECTION_STRING"
customer_db_connection       = "REPLACE_WITH_RDS_CONNECTION_STRING"
inventory_db_connection      = "REPLACE_WITH_RDS_CONNECTION_STRING"
order_db_connection          = "REPLACE_WITH_RDS_CONNECTION_STRING"
orderfulfillment_db_connection = "REPLACE_WITH_RDS_CONNECTION_STRING"
warehouse_db_connection      = "REPLACE_WITH_RDS_CONNECTION_STRING"

# ECS Configuration
ecs_cluster_name = "gemini-prod-cluster"
task_cpu         = "512"
task_memory      = "1024"
desired_count    = 2

# Image Tags
catalog_image_tag        = "v1.0.0"
customer_image_tag       = "v1.0.0"
inventory_image_tag      = "v1.0.0"
order_image_tag          = "v1.0.0"
orderfulfillment_image_tag = "v1.0.0"
warehouse_image_tag      = "v1.0.0"
gateway_image_tag        = "v1.0.0"

# Networking
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]

# ECR
ecr_repository_prefix = "gemini"

# Tags
tags = {
  Project     = "Gemini"
  Environment = "Production"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
