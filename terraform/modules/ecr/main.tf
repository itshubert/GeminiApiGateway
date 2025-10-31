# ECR Repositories for all microservices

locals {
  repositories = [
    "catalog",
    "customer",
    "inventory",
    "order",
    "orderfulfillment",
    "warehouse",
    "apigateway"
  ]
}

resource "aws_ecr_repository" "repositories" {
  for_each = toset(local.repositories)
  
  name                 = var.repository_prefix != "" ? "${var.repository_prefix}${each.key}" : "gemini${each.key}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name        = var.repository_prefix != "" ? "${var.repository_prefix}${each.key}" : "gemini${each.key}"
      Environment = var.environment
      Service     = each.key
    }
  )
}

# Lifecycle policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "repositories" {
  for_each   = aws_ecr_repository.repositories
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
