# LocalStack Environment - Variable Declarations
# These variables are defined in ../../variables.tf and overridden by terraform.tfvars

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "use_localstack" {
  description = "Whether to use LocalStack"
  type        = bool
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
}

variable "certificate_password" {
  description = "Password for ASPNET certificate"
  type        = string
  sensitive   = true
}

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

# SQS Queue URLs
variable "queue_order_submitted_inventory" {
  description = "Order Submitted queue URL for Inventory service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_inventory_reserved_order" {
  description = "Inventory Reserved queue URL for Order service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_order_stock_failed_order" {
  description = "Order Stock Failed queue URL for Order service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_order_shipped_order" {
  description = "Order Shipped queue URL for Order service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_inventory_reserved_fulfillment" {
  description = "Inventory Reserved queue URL for OrderFulfillment service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_order_submitted_fulfillment" {
  description = "Order Submitted queue URL for OrderFulfillment service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_job_inprogress_fulfillment" {
  description = "Job In Progress queue URL for OrderFulfillment service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_shipping_label_generated_fulfillment" {
  description = "Shipping Label Generated queue URL for OrderFulfillment service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "queue_fulfillment_task_created_warehouse" {
  description = "Fulfillment Task Created queue URL for Warehouse service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for ECS tasks"
  type        = string
}

variable "task_memory" {
  description = "Memory for ECS tasks in MB"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks per service"
  type        = number
}

variable "catalog_image_tag" {
  description = "Docker image tag for catalog service"
  type        = string
}

variable "customer_image_tag" {
  description = "Docker image tag for customer service"
  type        = string
}

variable "inventory_image_tag" {
  description = "Docker image tag for inventory service"
  type        = string
}

variable "order_image_tag" {
  description = "Docker image tag for order service"
  type        = string
}

variable "orderfulfillment_image_tag" {
  description = "Docker image tag for order fulfillment service"
  type        = string
}

variable "warehouse_image_tag" {
  description = "Docker image tag for warehouse service"
  type        = string
}

variable "gateway_image_tag" {
  description = "Docker image tag for API gateway"
  type        = string
}

variable "ecr_repository_prefix" {
  description = "Prefix for ECR repository names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
