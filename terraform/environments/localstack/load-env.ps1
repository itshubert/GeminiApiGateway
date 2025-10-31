# Load environment variables from .env file and export as TF_VAR_* variables
# This script reads the .env file and sets Terraform variables

Write-Host "Loading environment variables for Terraform..." -ForegroundColor Cyan

$envFile = ".env.localstack"

if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found at $envFile" -ForegroundColor Red
    exit 1
}

# Read .env file and set TF_VAR_ environment variables
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    
    # Skip empty lines and comments
    if ($line -and -not $line.StartsWith("#")) {
        # Parse key=value
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1]
            $value = $matches[2].Trim('"')
            
            # Map .env keys to Terraform variable names
            switch ($key) {
                "GeminiCatalogDbContext" {
                    $env:TF_VAR_catalog_db_connection = $value
                    Write-Host "  ✓ Set TF_VAR_catalog_db_connection" -ForegroundColor Green
                }
                "GeminiCustomerDbContext" {
                    $env:TF_VAR_customer_db_connection = $value
                    Write-Host "  ✓ Set TF_VAR_customer_db_connection" -ForegroundColor Green
                }
                "GeminiInventoryDbContext" {
                    $env:TF_VAR_inventory_db_connection = $value
                    Write-Host "  ✓ Set TF_VAR_inventory_db_connection" -ForegroundColor Green
                }
                "GeminiOrderDbContext" {
                    $env:TF_VAR_order_db_connection = $value
                    Write-Host "  ✓ Set TF_VAR_order_db_connection" -ForegroundColor Green
                }
                "GeminiOrderFulfillmentDbContext" {
                    $env:TF_VAR_orderfulfillment_db_connection = $value
                    Write-Host "  ✓ Set TF_VAR_orderfulfillment_db_connection" -ForegroundColor Green
                }
                "GeminiWarehouseDbContext" {
                    $env:TF_VAR_warehouse_db_connection = $value
                    Write-Host "  ✓ Set TF_VAR_warehouse_db_connection" -ForegroundColor Green
                }
                "CERTIFICATE_PASSWORD" {
                    $env:TF_VAR_certificate_password = $value
                    Write-Host "  ✓ Set TF_VAR_certificate_password" -ForegroundColor Green
                }
                # SQS Queue URLs - Inventory Service
                "QueueSettings__OrderSubmitted__Inventory" {
                    $env:TF_VAR_queue_order_submitted_inventory = $value
                    Write-Host "  ✓ Set TF_VAR_queue_order_submitted_inventory" -ForegroundColor Green
                }
                # SQS Queue URLs - Order Service
                "QueueSettings__InventoryReserved__Order" {
                    $env:TF_VAR_queue_inventory_reserved_order = $value
                    Write-Host "  ✓ Set TF_VAR_queue_inventory_reserved_order" -ForegroundColor Green
                }
                "QueueSettings__OrderStockFailed__Order" {
                    $env:TF_VAR_queue_order_stock_failed_order = $value
                    Write-Host "  ✓ Set TF_VAR_queue_order_stock_failed_order" -ForegroundColor Green
                }
                "QueueSettings__OrderShipped__Order" {
                    $env:TF_VAR_queue_order_shipped_order = $value
                    Write-Host "  ✓ Set TF_VAR_queue_order_shipped_order" -ForegroundColor Green
                }
                # SQS Queue URLs - OrderFulfillment Service
                "QueueSettings__InventoryReserved__Fulfillment" {
                    $env:TF_VAR_queue_inventory_reserved_fulfillment = $value
                    Write-Host "  ✓ Set TF_VAR_queue_inventory_reserved_fulfillment" -ForegroundColor Green
                }
                "QueueSettings__OrderSubmitted__Fulfillment" {
                    $env:TF_VAR_queue_order_submitted_fulfillment = $value
                    Write-Host "  ✓ Set TF_VAR_queue_order_submitted_fulfillment" -ForegroundColor Green
                }
                "QueueSettings__JobInProgress__Fulfillment" {
                    $env:TF_VAR_queue_job_inprogress_fulfillment = $value
                    Write-Host "  ✓ Set TF_VAR_queue_job_inprogress_fulfillment" -ForegroundColor Green
                }
                "QueueSettings__ShippingLabelGenerated__Fulfillment" {
                    $env:TF_VAR_queue_shipping_label_generated_fulfillment = $value
                    Write-Host "  ✓ Set TF_VAR_queue_shipping_label_generated_fulfillment" -ForegroundColor Green
                }
                # SQS Queue URLs - Warehouse Service
                "QueueSettings__FulfillmentTaskCreated__Warehouse" {
                    $env:TF_VAR_queue_fulfillment_task_created_warehouse = $value
                    Write-Host "  ✓ Set TF_VAR_queue_fulfillment_task_created_warehouse" -ForegroundColor Green
                }
            }
        }
    }
}

Write-Host "`nEnvironment variables loaded successfully!" -ForegroundColor Green
Write-Host "You can now run: terraform plan or terraform apply" -ForegroundColor Yellow
Write-Host "`nNote: These variables are only set for this PowerShell session." -ForegroundColor Gray
