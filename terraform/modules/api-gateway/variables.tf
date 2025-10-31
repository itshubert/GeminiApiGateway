# API Gateway Module - REST API to route to ECS services

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "gemini-api"
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener for VPC Link integration"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
