# CloudWatch Log Group for the service
resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "/ecs/${var.cluster_name}/${var.service_name}"
      Environment = var.environment
      Service     = var.service_name
    }
  )
}

# Task Definition
resource "aws_ecs_task_definition" "service" {
  family                   = "${var.project_name}-${var.environment}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in var.environment_variables : {
          name  = key
          value = value
        }
      ]

      secrets = var.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}"
      Environment = var.environment
      Service     = var.service_name
    }
  )
}

# Target Group (if ALB is used)
resource "aws_lb_target_group" "service" {
  count       = var.alb_listener_arn != "" ? 1 : 0
  name        = "${var.project_name}-${var.environment}-${var.service_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}-tg"
      Environment = var.environment
      Service     = var.service_name
    }
  )
}

# ALB Listener Rule (if ALB is used and path patterns are provided)
resource "aws_lb_listener_rule" "service" {
  count        = var.alb_listener_arn != "" && length(var.path_patterns) > 0 && var.listener_rule_enabled ? 1 : 0
  listener_arn = var.alb_listener_arn
  priority     = var.alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[0].arn
  }

  condition {
    path_pattern {
      values = var.path_patterns
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}-rule"
      Environment = var.environment
      Service     = var.service_name
    }
  )
}

# Service Discovery Service (for internal service-to-service communication)
resource "aws_service_discovery_service" "service" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.service_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}-sd"
      Environment = var.environment
      Service     = var.service_name
    }
  )
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-${var.environment}-${var.service_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.alb_listener_arn != "" ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.service[0].arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.service[0].arn
    }
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}"
      Environment = var.environment
      Service     = var.service_name
    }
  )

  depends_on = [
    aws_lb_target_group.service,
    aws_service_discovery_service.service
  ]
}

data "aws_region" "current" {}
