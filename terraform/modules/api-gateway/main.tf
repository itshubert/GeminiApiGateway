# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-${var.api_name}"
  description = "API Gateway for ${var.project_name} ${var.environment} services"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.api_name}"
      Environment = var.environment
    }
  )
}

# VPC Link for private ALB integration
resource "aws_api_gateway_vpc_link" "main" {
  name        = "${var.project_name}-${var.environment}-vpc-link"
  description = "VPC Link to ALB for ${var.project_name}"
  target_arns = [var.alb_listener_arn]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-link"
      Environment = var.environment
    }
  )
}

# Define service resources and methods based on Ocelot configuration
locals {
  # Map service routes based on your Ocelot config
  routes = {
    # Catalog Service (products, categories) - Port 4000
    products = {
      path_part = "products"
      methods   = ["GET", "POST", "OPTIONS"]
      alb_path  = "/products"
    }
    categories = {
      path_part = "categories"
      methods   = ["GET", "POST", "OPTIONS"]
      alb_path  = "/categories"
    }
    # Order Service - Port 4002
    orders = {
      path_part = "orders"
      methods   = ["GET", "POST", "OPTIONS"]
      alb_path  = "/orders"
    }
    # Customer Service - Port 4004
    customers = {
      path_part = "customers"
      methods   = ["GET", "POST", "OPTIONS"]
      alb_path  = "/customers"
    }
    # Inventory Service - Port 4006
    inventory = {
      path_part = "inventory"
      methods   = ["GET", "POST", "OPTIONS"]
      alb_path  = "/inventory"
    }
    # Warehouse Service (jobs) - Port 4009
    jobs = {
      path_part = "jobs"
      methods   = ["GET", "POST", "OPTIONS"]
      alb_path  = "/jobs"
    }
  }
}

# Create resources for each service endpoint
resource "aws_api_gateway_resource" "services" {
  for_each = local.routes

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = each.value.path_part
}

# Create {proxy+} resource for each service (to handle sub-paths)
resource "aws_api_gateway_resource" "service_proxy" {
  for_each = local.routes

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.services[each.key].id
  path_part   = "{proxy+}"
}

# Create methods for root path of each service
resource "aws_api_gateway_method" "service_root" {
  for_each = { for k, v in local.routes : k => v }

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.services[each.key].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = false
  }
}

# Create methods for proxy path of each service
resource "aws_api_gateway_method" "service_proxy" {
  for_each = { for k, v in local.routes : k => v }

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.service_proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integration for root path - forward to ALB
resource "aws_api_gateway_integration" "service_root" {
  for_each = local.routes

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.services[each.key].id
  http_method = aws_api_gateway_method.service_root[each.key].http_method

  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}${each.value.alb_path}"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main.id

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Integration for proxy path - forward to ALB with sub-path
resource "aws_api_gateway_integration" "service_proxy" {
  for_each = local.routes

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.service_proxy[each.key].id
  http_method = aws_api_gateway_method.service_proxy[each.key].http_method

  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}${each.value.alb_path}/{proxy}"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main.id

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Deploy the API
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Force new deployment when configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.main.body,
      aws_api_gateway_resource.services,
      aws_api_gateway_resource.service_proxy,
      aws_api_gateway_method.service_root,
      aws_api_gateway_method.service_proxy,
      aws_api_gateway_integration.service_root,
      aws_api_gateway_integration.service_proxy,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.service_root,
    aws_api_gateway_integration.service_proxy
  ]
}

# Create stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  # Enable CloudWatch Logs
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.stage_name}"
      Environment = var.environment
    }
  )
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-${var.api_name}"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "/aws/apigateway/${var.project_name}-${var.environment}-${var.api_name}"
      Environment = var.environment
    }
  )
}

# Method Settings for logging
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}
