output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.service.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.service.arn
}

output "target_group_arn" {
  description = "ARN of the target group (if created)"
  value       = var.alb_listener_arn != "" ? aws_lb_target_group.service[0].arn : null
}

output "service_discovery_arn" {
  description = "ARN of the service discovery service (if created)"
  value       = var.enable_service_discovery && var.service_discovery_namespace_id != "" ? aws_service_discovery_service.service[0].arn : null
}

output "service_endpoint" {
  description = "Internal service endpoint for service-to-service communication"
  value       = var.enable_service_discovery && var.service_discovery_namespace_id != "" ? "${var.service_name}.${var.environment}.local" : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.service.name
}
