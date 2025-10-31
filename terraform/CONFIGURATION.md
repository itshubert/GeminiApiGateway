# 🔧 Service Configuration Guide

This guide explains how your ECS services receive their configuration (database connection strings, SQS queue URLs, etc.) in the Terraform infrastructure.

## 📋 Overview

Your services running in ECS receive configuration through **two primary methods**:

1. **Environment Variables** - Plain text configuration passed directly
2. **Secrets** - Sensitive data from AWS Secrets Manager or Systems Manager Parameter Store

## 🔄 How It Works Now vs. Docker Compose

### Before (Docker Compose)
```yaml
services:
  catalog:
    environment:
      - ConnectionStrings__GeminiCatalogDbContext=Server=...
      - QueueSettings__SomeQueue=https://sqs...
```

### After (Terraform + ECS)
```hcl
module "catalog_service" {
  source = "../../modules/ecs-service"
  
  environment_variables = {
    ConnectionStrings__GeminiCatalogDbContext = var.catalog_db_connection
    AWS__Region                               = var.aws_region
  }
  
  secrets = [
    {
      name      = "ConnectionStrings__GeminiCatalogDbContext"
      valueFrom = "arn:aws:secretsmanager:us-east-1:123456:secret:gemini/prod/catalog-db"
    }
  ]
}
```

## 1️⃣ Database Connection Strings

### Current Implementation (Variables in terraform.tfvars)

**File**: `terraform/environments/aws/main.tf`
```hcl
module "catalog_service" {
  # ... other config ...
  
  environment_variables = {
    ASPNETCORE_ENVIRONMENT                    = "Production"
    ASPNETCORE_URLS                          = "http://+:80"
    ConnectionStrings__GeminiCatalogDbContext = var.catalog_db_connection
    AWS__UseLocalStack                        = "false"
    AWS__Region                              = var.aws_region
  }
}
```

**File**: `terraform/environments/aws/terraform.tfvars`
```hcl
catalog_db_connection = "Server=mydb.rds.amazonaws.com;Database=GeminiCatalog;User Id=admin;Password=secret123;"
```

⚠️ **Security Warning**: This approach stores sensitive data in `terraform.tfvars`. For production, use Secrets Manager (see below).

### ✅ Recommended: AWS Secrets Manager (Production)

#### Step 1: Store secrets in AWS Secrets Manager
```powershell
# Create database connection string secrets
aws secretsmanager create-secret `
  --name "gemini/prod/catalog-db" `
  --description "Catalog service database connection" `
  --secret-string "Server=mydb.rds.amazonaws.com;Database=GeminiCatalog;User Id=admin;Password=secret123;" `
  --region us-east-1

aws secretsmanager create-secret `
  --name "gemini/prod/customer-db" `
  --secret-string "Server=mydb.rds.amazonaws.com;Database=GeminiCustomer;..." `
  --region us-east-1

# Repeat for each service...
```

#### Step 2: Update your service configuration

**File**: `terraform/environments/aws/main.tf`
```hcl
module "catalog_service" {
  source = "../../modules/ecs-service"
  
  # ... other config ...
  
  # Remove from environment_variables, add to secrets
  environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Production"
    ASPNETCORE_URLS       = "http://+:80"
    AWS__UseLocalStack    = "false"
    AWS__Region           = var.aws_region
  }
  
  # Add secrets configuration
  secrets = [
    {
      name      = "ConnectionStrings__GeminiCatalogDbContext"
      valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:gemini/prod/catalog-db-AbCdEf"
    }
  ]
}
```

#### Step 3: Update IAM task role permissions

The ECS task execution role needs permission to read secrets:

**File**: `terraform/modules/ecs-cluster/main.tf` (add to existing policy)
```hcl
resource "aws_iam_role_policy" "task_execution_secrets" {
  name = "${var.project_name}-${var.environment}-task-execution-secrets"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:gemini/${var.environment}/*"
        ]
      }
    ]
  })
}
```

## 2️⃣ SQS Queue URLs

Since you're managing SQS queues in a **separate project**, you have several options:

### Option A: Terraform Remote State (Recommended)

If your SQS project uses Terraform, reference its state:

**In your SQS project** (`terraform/outputs.tf`):
```hcl
output "queue_urls" {
  description = "SQS Queue URLs"
  value = {
    order_submitted_inventory        = aws_sqs_queue.order_submitted_inventory.url
    inventory_reserved_order         = aws_sqs_queue.inventory_reserved_order.url
    order_stock_failed_order         = aws_sqs_queue.order_stock_failed_order.url
    fulfillment_ordershipped_order   = aws_sqs_queue.fulfillment_ordershipped_order.url
    # ... other queues
  }
}
```

**In this project** (`terraform/environments/aws/main.tf`):
```hcl
# Add data source to read remote state
data "terraform_remote_state" "queues" {
  backend = "s3"
  config = {
    bucket = "your-sqs-terraform-state-bucket"
    key    = "queues/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use in service configuration
module "inventory_service" {
  # ... other config ...
  
  environment_variables = {
    # ... other vars ...
    QueueSettings__OrderSubmitted = data.terraform_remote_state.queues.outputs.queue_urls["order_submitted_inventory"]
  }
}

module "order_service" {
  # ... other config ...
  
  environment_variables = {
    # ... other vars ...
    QueueSettings__InventoryReserved = data.terraform_remote_state.queues.outputs.queue_urls["inventory_reserved_order"]
    QueueSettings__OrderStockFailed  = data.terraform_remote_state.queues.outputs.queue_urls["order_stock_failed_order"]
    QueueSettings__OrderShipped      = data.terraform_remote_state.queues.outputs.queue_urls["fulfillment_ordershipped_order"]
  }
}
```

### Option B: AWS Systems Manager Parameter Store

Store queue URLs in Parameter Store from your SQS project:

```powershell
# From your SQS project, store queue URLs
aws ssm put-parameter `
  --name "/gemini/prod/queues/order-submitted-inventory" `
  --value "https://sqs.us-east-1.amazonaws.com/123456/order-submitted-inventory.fifo" `
  --type String `
  --region us-east-1

# Repeat for each queue...
```

Then reference in Terraform:

```hcl
# Add data sources
data "aws_ssm_parameter" "order_submitted_queue" {
  name = "/gemini/prod/queues/order-submitted-inventory"
}

data "aws_ssm_parameter" "inventory_reserved_queue" {
  name = "/gemini/prod/queues/inventory-reserved-order"
}

# Use in service configuration
module "inventory_service" {
  # ... other config ...
  
  environment_variables = {
    # ... other vars ...
    QueueSettings__OrderSubmitted = data.aws_ssm_parameter.order_submitted_queue.value
  }
}
```

### Option C: Manual Variables (Quick but not automated)

Add queue URL variables to `terraform/environments/aws/variables.tf`:

```hcl
variable "order_submitted_queue_url" {
  description = "URL of the order submitted queue"
  type        = string
  sensitive   = true
}

variable "inventory_reserved_queue_url" {
  description = "URL of the inventory reserved queue"
  type        = string
  sensitive   = true
}

# ... add more queue variables
```

Set values in `terraform.tfvars`:

```hcl
order_submitted_queue_url    = "https://sqs.us-east-1.amazonaws.com/123456/order-submitted.fifo"
inventory_reserved_queue_url = "https://sqs.us-east-1.amazonaws.com/123456/inventory-reserved.fifo"
```

Use in services:

```hcl
module "inventory_service" {
  # ... other config ...
  
  environment_variables = {
    # ... other vars ...
    QueueSettings__OrderSubmitted = var.order_submitted_queue_url
  }
}
```

### Option D: Secrets Manager (Most Secure)

Store queue URLs as secrets (similar to database connections):

```powershell
# Create a single secret with all queue URLs
aws secretsmanager create-secret `
  --name "gemini/prod/queue-urls" `
  --secret-string '{
    "OrderSubmittedInventory": "https://sqs...",
    "InventoryReservedOrder": "https://sqs...",
    "OrderStockFailedOrder": "https://sqs..."
  }' `
  --region us-east-1
```

Then use individual keys in your application code, or use the `secrets` parameter in Terraform.

## 3️⃣ Complete Example: Inventory Service with Queues

Here's a complete example showing how to configure the Inventory service with both database and queue configuration:

### Using Remote State (Recommended)

```hcl
# Data source for SQS project
data "terraform_remote_state" "queues" {
  backend = "s3"
  config = {
    bucket = "your-sqs-terraform-state-bucket"
    key    = "queues/terraform.tfstate"
    region = "us-east-1"
  }
}

# Inventory Service
module "inventory_service" {
  source = "../../modules/ecs-service"

  project_name                  = var.project_name
  environment                   = var.environment
  service_name                  = "inventory"
  cluster_id                    = module.ecs_cluster.cluster_id
  cluster_name                  = module.ecs_cluster.cluster_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  security_group_ids            = [module.networking.ecs_security_group_id]
  task_execution_role_arn       = module.ecs_cluster.task_execution_role_arn
  task_role_arn                 = module.ecs_cluster.task_role_arn
  container_image               = "${module.ecr.repository_urls["inventory"]}:${var.inventory_image_tag}"
  container_port                = 80
  cpu                           = var.task_cpu
  memory                        = var.task_memory
  desired_count                 = var.desired_count
  alb_listener_arn              = module.networking.alb_listener_arn
  listener_rule_enabled         = false
  service_discovery_namespace_id = module.service_discovery.namespace_id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT                    = "Production"
    ASPNETCORE_URLS                          = "http://+:80"
    AWS__UseLocalStack                        = "false"
    AWS__Region                              = var.aws_region
    # Queue URLs from remote state
    QueueSettings__OrderSubmitted             = data.terraform_remote_state.queues.outputs.queue_urls["order_submitted_inventory"]
  }

  # Database connection from Secrets Manager
  secrets = [
    {
      name      = "ConnectionStrings__GeminiInventoryDbContext"
      valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:gemini/prod/inventory-db-AbCdEf"
    }
  ]

  tags = var.tags
}
```

## 4️⃣ LocalStack (Development) Configuration

For LocalStack, you can use simpler configuration since it's not production:

**File**: `terraform/environments/localstack/terraform.tfvars`
```hcl
catalog_db_connection = "Server=host.docker.internal,1433;Database=GeminiCatalog;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True"

# Or use LocalStack's internal services
catalog_db_connection = "Server=localstack,4566;..."
```

Environment variables are passed the same way, just with LocalStack-specific values.

## 5️⃣ IAM Permissions Summary

Your ECS tasks need these IAM permissions:

### Task Execution Role (pulls images, writes logs, reads secrets)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters"
      ],
      "Resource": "*"
    }
  ]
}
```

### Task Role (application runtime permissions)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:us-east-1:123456789012:*"
    }
  ]
}
```

## 6️⃣ Best Practices

### ✅ DO:
- **Use Secrets Manager** for database passwords and sensitive config
- **Use Parameter Store** for non-sensitive but centralized config
- **Use Remote State** to share outputs between Terraform projects
- **Never commit** `terraform.tfvars` with real credentials
- **Use different secrets** per environment (dev/staging/prod)
- **Rotate secrets** regularly using AWS Secrets Manager rotation

### ❌ DON'T:
- Store passwords in plain text in `terraform.tfvars`
- Commit sensitive data to Git
- Use the same credentials across environments
- Hardcode queue URLs in application code

## 7️⃣ Migration Checklist

To migrate from your current setup:

- [ ] **Step 1**: Store DB connection strings in AWS Secrets Manager
- [ ] **Step 2**: Update ECS task execution role with Secrets Manager permissions
- [ ] **Step 3**: Update service modules to use `secrets` parameter instead of `environment_variables` for sensitive data
- [ ] **Step 4**: Set up remote state data source for your SQS project (or use Parameter Store)
- [ ] **Step 5**: Add queue URLs to service configurations
- [ ] **Step 6**: Update task role with SQS permissions
- [ ] **Step 7**: Test in LocalStack first
- [ ] **Step 8**: Deploy to production

## 🔍 Debugging Configuration

### View environment variables in running task:
```powershell
# Get task ARN
aws ecs list-tasks --cluster gemini-prod-cluster --service-name gemini-prod-inventory

# Describe task to see environment variables
aws ecs describe-tasks --cluster gemini-prod-cluster --tasks <task-arn>
```

### View logs to verify configuration:
```powershell
aws logs tail /ecs/gemini-prod-cluster/inventory --follow
```

### Test secret retrieval:
```powershell
aws secretsmanager get-secret-value --secret-id gemini/prod/catalog-db
```

## 📚 Related Documentation

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [Terraform Remote State](https://www.terraform.io/language/state/remote-state-data)
- [ECS Task IAM Roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)

## 💡 Quick Reference

| Configuration Type | Method | Security | Recommendation |
|-------------------|--------|----------|----------------|
| Database Passwords | Secrets Manager | 🔒 High | ✅ Use for prod |
| Queue URLs | Remote State / Parameter Store | 🔓 Low-Medium | ✅ Recommended |
| API Keys | Secrets Manager | 🔒 High | ✅ Use for prod |
| Feature Flags | Parameter Store | 🔓 Low | ✅ Easy updates |
| Environment Name | Environment Variables | 🔓 Low | ✅ Simple |
| AWS Region | Environment Variables | 🔓 Low | ✅ Simple |

---

**Need Help?** Check `CHANGES.md` for recent updates or `README.md` for general documentation.
