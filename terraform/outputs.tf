# Shared outputs

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.networking.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.networking.alb_zone_id
}

output "service_endpoints" {
  description = "Internal service endpoints"
  value = {
    catalog           = module.catalog_service.service_endpoint
    customer          = module.customer_service.service_endpoint
    inventory         = module.inventory_service.service_endpoint
    order             = module.order_service.service_endpoint
    orderfulfillment  = module.orderfulfillment_service.service_endpoint
    warehouse         = module.warehouse_service.service_endpoint
  }
}

output "sqs_queue_urls" {
  description = "SQS queue URLs"
  value       = module.sqs_queues.queue_urls
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}
