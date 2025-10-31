# ECS Service Module - Reusable module for deploying microservices

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "task_execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "host_port" {
  description = "Port on the host"
  type        = number
  default     = 80
}

variable "cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets from SSM or Secrets Manager"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener (optional)"
  type        = string
  default     = ""
}

variable "alb_priority" {
  description = "Priority for the ALB listener rule"
  type        = number
  default     = 100
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "path_patterns" {
  description = "Path patterns for ALB routing"
  type        = list(string)
  default     = []
}

variable "listener_rule_enabled" {
  description = "Whether to create ALB listener rule (disable for API Gateway integration)"
  type        = bool
  default     = true
}

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery"
  type        = bool
  default     = true
}

variable "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
