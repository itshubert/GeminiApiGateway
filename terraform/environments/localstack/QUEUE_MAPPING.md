# SQS Queue Mapping for LocalStack

This document shows how SQS queue URLs from docker-compose.yml are mapped to Terraform variables.

## 📋 Queue Configuration Overview

### Inventory Service
| Environment Variable | .env.localstack Key | Terraform Variable | Queue Name |
|---------------------|---------------------|-------------------|------------|
| `QueueSettings__OrderSubmitted` | `QueueSettings__OrderSubmitted__Inventory` | `queue_order_submitted_inventory` | `order-submitted-inventory.fifo` |

**Usage in Terraform** (`main.tf`):
```hcl
module "inventory_service" {
  environment_variables = {
    QueueSettings__OrderSubmitted = var.queue_order_submitted_inventory
  }
}
```

---

### Order Service
| Environment Variable | .env.localstack Key | Terraform Variable | Queue Name |
|---------------------|---------------------|-------------------|------------|
| `QueueSettings__InventoryReserved` | `QueueSettings__InventoryReserved__Order` | `queue_inventory_reserved_order` | `inventory-reserved-order.fifo` |
| `QueueSettings__OrderStockFailed` | `QueueSettings__OrderStockFailed__Order` | `queue_order_stock_failed_order` | `order-stock-failed-order.fifo` |
| `Queue_Settings__OrderShipped` | `QueueSettings__OrderShipped__Order` | `queue_order_shipped_order` | `fulfillment-ordershipped-order.fifo` |

**Usage in Terraform** (`main.tf`):
```hcl
module "order_service" {
  environment_variables = {
    QueueSettings__InventoryReserved = var.queue_inventory_reserved_order
    QueueSettings__OrderStockFailed  = var.queue_order_stock_failed_order
    Queue_Settings__OrderShipped     = var.queue_order_shipped_order
  }
}
```

---

### OrderFulfillment Service
| Environment Variable | .env.localstack Key | Terraform Variable | Queue Name |
|---------------------|---------------------|-------------------|------------|
| `QueueSettings__InventoryReserved` | `QueueSettings__InventoryReserved__Fulfillment` | `queue_inventory_reserved_fulfillment` | `inventory-reserved-fulfillment.fifo` |
| `QueueSettings__OrderSubmitted` | `QueueSettings__OrderSubmitted__Fulfillment` | `queue_order_submitted_fulfillment` | `order-submitted-fulfillment.fifo` |
| `QueueSettings__JobInProgress` | `QueueSettings__JobInProgress__Fulfillment` | `queue_job_inprogress_fulfillment` | `job-pickinprogress-order.fifo` |
| `QueueSettings__ShippingLabelGenerated` | `QueueSettings__ShippingLabelGenerated__Fulfillment` | `queue_shipping_label_generated_fulfillment` | `shipping-labelgenerated-fulfillment.fifo` |

**Usage in Terraform** (`main.tf`):
```hcl
module "orderfulfillment_service" {
  environment_variables = {
    QueueSettings__InventoryReserved        = var.queue_inventory_reserved_fulfillment
    QueueSettings__OrderSubmitted           = var.queue_order_submitted_fulfillment
    QueueSettings__JobInProgress            = var.queue_job_inprogress_fulfillment
    QueueSettings__ShippingLabelGenerated   = var.queue_shipping_label_generated_fulfillment
  }
}
```

---

### Warehouse Service
| Environment Variable | .env.localstack Key | Terraform Variable | Queue Name |
|---------------------|---------------------|-------------------|------------|
| `QueueSettings__FulfillmentTaskCreated` | `QueueSettings__FulfillmentTaskCreated__Warehouse` | `queue_fulfillment_task_created_warehouse` | `fulfillment-task-created-warehouse.fifo` |

**Usage in Terraform** (`main.tf`):
```hcl
module "warehouse_service" {
  environment_variables = {
    QueueSettings__FulfillmentTaskCreated = var.queue_fulfillment_task_created_warehouse
  }
}
```

---

## 🔄 Loading Queue URLs

### Method 1: Use load-env.ps1 (Recommended)
```powershell
cd terraform/environments/localstack
.\load-env.ps1
terraform plan
```

The script reads `.env.localstack` and converts:
```
QueueSettings__OrderSubmitted__Inventory="http://sqs..."
```
to:
```powershell
$env:TF_VAR_queue_order_submitted_inventory = "http://sqs..."
```

### Method 2: Set Manually
```powershell
$env:TF_VAR_queue_order_submitted_inventory = "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/order-submitted-inventory.fifo"
$env:TF_VAR_queue_inventory_reserved_order = "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/inventory-reserved-order.fifo"
# ... etc
```

---

## 📊 Complete Queue List

All queues are FIFO queues in LocalStack:

```
http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/
├── order-submitted-inventory.fifo
├── inventory-reserved-order.fifo
├── order-stock-failed-order.fifo
├── fulfillment-ordershipped-order.fifo
├── inventory-reserved-fulfillment.fifo
├── order-submitted-fulfillment.fifo
├── job-pickinprogress-order.fifo
├── shipping-labelgenerated-fulfillment.fifo
└── fulfillment-task-created-warehouse.fifo
```

---

## 🚀 Quick Start

1. **Ensure queues exist in LocalStack** (created by your SQS management project)

2. **Load environment variables**:
   ```powershell
   cd terraform/environments/localstack
   .\load-env.ps1
   ```

3. **Verify variables are set**:
   ```powershell
   echo $env:TF_VAR_queue_order_submitted_inventory
   ```

4. **Apply Terraform**:
   ```powershell
   terraform plan
   terraform apply
   ```

---

## 🔍 Troubleshooting

### Queue URLs not being set?
Check that `.env.localstack` has the correct key names:
```bash
Get-Content .env.localstack | Select-String "QueueSettings"
```

### Services can't connect to queues?
1. Verify LocalStack is running: `localstack status`
2. Check queue exists: `aws --endpoint-url=http://localhost:4566 sqs list-queues`
3. Verify queue URL in container logs

### Need to update queue URLs?
1. Edit `.env.localstack`
2. Run `.\load-env.ps1` again
3. Run `terraform apply` to update services

---

## 📝 Notes

- All queue URLs use LocalStack's endpoint: `http://sqs.us-east-1.localhost.localstack.cloud:4566`
- Account ID is always `000000000000` in LocalStack
- Queue names match those in docker-compose.yml
- Variables have default value `""` so they're optional if queues aren't needed

---

**See also**: 
- `CONFIGURATION.md` - Full configuration guide
- `ENV_USAGE.md` - Using .env files with Terraform
- `.env.localstack` - Environment variables file
