# Load environment variables from .env file and export as TF_VAR_* variables
# This script reads the .env file and sets Terraform variables for AWS/Production

Write-Host "Loading environment variables for Terraform (AWS)..." -ForegroundColor Cyan

$envFile = ".env"

if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found at $envFile" -ForegroundColor Red
    Write-Host "Please create a .env file in the project root or specify the path." -ForegroundColor Yellow
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
            }
        }
    }
}

Write-Host "`nEnvironment variables loaded successfully!" -ForegroundColor Green
Write-Host "You can now run: terraform plan or terraform apply" -ForegroundColor Yellow
Write-Host "`nNote: These variables are only set for this PowerShell session." -ForegroundColor Gray
