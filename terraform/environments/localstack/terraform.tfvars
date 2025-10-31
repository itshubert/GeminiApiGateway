# LocalStack Environment Variables

environment          = "localstack"
aws_region           = "us-east-1"
project_name         = "gemini"
use_localstack       = true
localstack_endpoint  = "http://localhost:4566"

# Certificate password (use a secure value)
certificate_password = "YourSecurePassword123!"

# Database Connection Strings (update with your actual values)
catalog_db_connection        = "Host=postgres;Port=5432;Database=geminicatalog;Username=postgres;Password=Blackbox57!"
customer_db_connection       = "Host=postgres;Port=5432;Database=geminicustomer;Username=postgres;Password=Blackbox57!"
inventory_db_connection      = "Host=postgres;Port=5432;Database=geminiinventory;Username=postgres;Password=Blackbox57!"
order_db_connection          = "Host=postgres;Port=5432;Database=geminiorder;Username=postgres;Password=Blackbox57!"
orderfulfillment_db_connection = "Host=postgres;Port=5432;Database=geminifulfillment;Username=postgres;Password=Blackbox57!"
warehouse_db_connection      = "Host=postgres;Port=5432;Database=geminiwarehouse;Username=postgres;Password=Blackbox57!"

# ECS Configuration
ecs_cluster_name = "gemini-localstack-cluster"
task_cpu         = "256"
task_memory      = "512"
desired_count    = 1

# Image Tags
catalog_image_tag        = "latest"
customer_image_tag       = "latest"
inventory_image_tag      = "latest"
order_image_tag          = "latest"
orderfulfillment_image_tag = "latest"
warehouse_image_tag      = "latest"
gateway_image_tag        = "latest"

# Networking
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# ECR
ecr_repository_prefix = "gemini"

# Tags
tags = {
  Project     = "Gemini"
  Environment = "LocalStack"
  ManagedBy   = "Terraform"
}
