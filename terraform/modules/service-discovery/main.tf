# AWS Cloud Map Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.environment}.local"
  description = "Private DNS namespace for ${var.project_name} ${var.environment} services"
  vpc         = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-namespace"
      Environment = var.environment
    }
  )
}
