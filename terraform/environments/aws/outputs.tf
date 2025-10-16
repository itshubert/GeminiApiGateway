# Outputs for AWS Production environment

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.networking.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "service_endpoints" {
  description = "Internal service endpoints (Service Discovery)"
  value = {
    catalog          = module.catalog_service.service_endpoint
    customer         = module.customer_service.service_endpoint
    inventory        = module.inventory_service.service_endpoint
    order            = module.order_service.service_endpoint
    orderfulfillment = module.orderfulfillment_service.service_endpoint
    warehouse        = module.warehouse_service.service_endpoint
  }
}

output "api_gateway_url" {
  description = "API Gateway endpoint URL (use this for external access)"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_service_urls" {
  description = "Individual service URLs via API Gateway"
  value = {
    products   = "${module.api_gateway.api_endpoint}/products"
    categories = "${module.api_gateway.api_endpoint}/categories"
    orders     = "${module.api_gateway.api_endpoint}/orders"
    customers  = "${module.api_gateway.api_endpoint}/customers"
    inventory  = "${module.api_gateway.api_endpoint}/inventory"
    jobs       = "${module.api_gateway.api_endpoint}/jobs"
  }
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}
