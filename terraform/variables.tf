# Shared variables for all environments

variable "environment" {
  description = "Environment name (localstack, dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "gemini"
}

variable "use_localstack" {
  description = "Whether to use LocalStack endpoints"
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4566"
}

variable "certificate_password" {
  description = "Password for ASPNET certificate"
  type        = string
  sensitive   = true
}

# Database connection strings
variable "catalog_db_connection" {
  description = "Catalog service database connection string"
  type        = string
  sensitive   = true
}

variable "customer_db_connection" {
  description = "Customer service database connection string"
  type        = string
  sensitive   = true
}

variable "inventory_db_connection" {
  description = "Inventory service database connection string"
  type        = string
  sensitive   = true
}

variable "order_db_connection" {
  description = "Order service database connection string"
  type        = string
  sensitive   = true
}

variable "orderfulfillment_db_connection" {
  description = "Order Fulfillment service database connection string"
  type        = string
  sensitive   = true
}

variable "warehouse_db_connection" {
  description = "Warehouse service database connection string"
  type        = string
  sensitive   = true
}

# ECS Configuration
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "gemini-cluster"
}

variable "task_cpu" {
  description = "CPU units for ECS tasks (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for ECS tasks in MB (512, 1024, 2048, etc)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of tasks per service"
  type        = number
  default     = 1
}

# Service Image Tags
variable "catalog_image_tag" {
  description = "Docker image tag for catalog service"
  type        = string
  default     = "latest"
}

variable "customer_image_tag" {
  description = "Docker image tag for customer service"
  type        = string
  default     = "latest"
}

variable "inventory_image_tag" {
  description = "Docker image tag for inventory service"
  type        = string
  default     = "latest"
}

variable "order_image_tag" {
  description = "Docker image tag for order service"
  type        = string
  default     = "latest"
}

variable "orderfulfillment_image_tag" {
  description = "Docker image tag for order fulfillment service"
  type        = string
  default     = "latest"
}

variable "warehouse_image_tag" {
  description = "Docker image tag for warehouse service"
  type        = string
  default     = "latest"
}

variable "gateway_image_tag" {
  description = "Docker image tag for API gateway"
  type        = string
  default     = "latest"
}

# ECR Configuration
variable "ecr_repository_prefix" {
  description = "Prefix for ECR repository names"
  type        = string
  default     = "gemini"
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
