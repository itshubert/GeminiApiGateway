# Troubleshooting LocalStack Deployment

## 🚨 Common Issue: "Invalid Security Token" Error

### Problem:
When running `terraform apply`, you see:
```
Error: error configuring Terraform AWS Provider: invalid security token
```

### Why This Happens:
Terraform is trying to connect to **real AWS** instead of **LocalStack**.

### ✅ Solutions:

#### Solution 1: Verify LocalStack is Running
```powershell
# Check LocalStack status
docker ps | Select-String localstack

# Check LocalStack health
curl http://localhost:4566/_localstack/health

# If not running, start it:
docker-compose up -d localstack
```

#### Solution 2: Verify Provider Configuration
The `terraform/environments/localstack/main.tf` should have:

```hcl
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway       = var.localstack_endpoint  # http://localhost:4566
    ec2              = var.localstack_endpoint
    ecr              = var.localstack_endpoint
    ecs              = var.localstack_endpoint
    elb              = var.localstack_endpoint  # Important for ALB!
    elbv2            = var.localstack_endpoint  # Important for ALB!
    cloudwatch       = var.localstack_endpoint
    iam              = var.localstack_endpoint
    s3               = var.localstack_endpoint
    servicediscovery = var.localstack_endpoint
    # ... other endpoints
  }
}
```

**Key Points:**
- `access_key` and `secret_key` are set to `"test"` (LocalStack accepts any value)
- `skip_*` flags prevent Terraform from validating against real AWS
- All endpoints point to `http://localhost:4566`

#### Solution 3: Check Environment Variables
Make sure you don't have AWS credentials set that override the provider config:

```powershell
# These should NOT be set when deploying to LocalStack
$env:AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY
$env:AWS_SESSION_TOKEN

# If they are set, unset them:
Remove-Item Env:\AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:\AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:\AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
```

#### Solution 4: Verify terraform.tfvars
Check that `localstack_endpoint` is correctly set:

```hcl
# terraform/environments/localstack/terraform.tfvars
localstack_endpoint = "http://localhost:4566"
```

If LocalStack is in Docker, it might be:
```hcl
localstack_endpoint = "http://localstack:4566"  # From within Docker network
```

#### Solution 5: Re-initialize Terraform
Sometimes the provider cache needs to be refreshed:

```powershell
cd terraform\environments\localstack
terraform init -upgrade
terraform plan
```

## 🔧 Complete Troubleshooting Steps

### Step 1: Verify LocalStack
```powershell
# Check if running
docker ps | Select-String localstack

# If not running:
cd D:\DevTest\Gemini-OPS\GeminiApiGateway
docker-compose up -d localstack

# Wait a few seconds, then check health
Start-Sleep -Seconds 5
curl http://localhost:4566/_localstack/health
```

Expected response shows services as "available" or "running".

### Step 2: Check LocalStack Services
```powershell
# List services
curl http://localhost:4566/_localstack/health | ConvertFrom-Json | Select-Object -ExpandProperty services

# You need these services:
# - iam, ec2, ecs, ecr, elbv2, apigateway, logs, cloudwatch, servicediscovery, s3
```

### Step 3: Test LocalStack Connectivity
```powershell
# Test S3 endpoint
aws --endpoint-url=http://localhost:4566 s3 ls

# Test ECS endpoint
aws --endpoint-url=http://localhost:4566 ecs list-clusters
```

### Step 4: Clear AWS Environment Variables
```powershell
# Remove any AWS credentials that might interfere
$env:AWS_ACCESS_KEY_ID = $null
$env:AWS_SECRET_ACCESS_KEY = $null
$env:AWS_SESSION_TOKEN = $null
$env:AWS_PROFILE = $null

# Or restart PowerShell to ensure clean state
```

### Step 5: Verify Terraform Variables
```powershell
cd terraform\environments\localstack

# Load environment variables
.\load-env.ps1

# Verify localstack_endpoint
terraform console
> var.localstack_endpoint
"http://localhost:4566"
> exit
```

### Step 6: Clean and Re-plan
```powershell
# Remove old state (if needed)
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue
Remove-Item -Recurse .terraform -ErrorAction SilentlyContinue

# Re-initialize
terraform init

# Plan again
terraform plan
```

## 🐛 Specific Error Messages

### Error: "invalid security token"
**Cause:** Terraform is using real AWS credentials or can't reach LocalStack  
**Fix:** Follow Solution 3 above (clear environment variables)

### Error: "no valid credential sources found"
**Cause:** Provider config missing `access_key` and `secret_key`  
**Fix:** Add `access_key = "test"` and `secret_key = "test"` to provider block

### Error: "connection refused"
**Cause:** LocalStack isn't running or wrong endpoint  
**Fix:** Start LocalStack with `docker-compose up -d localstack`

### Error: "service not enabled"
**Cause:** LocalStack missing required services  
**Fix:** Update LocalStack SERVICES environment variable (see LOCALSTACK_SERVICES.md)

## 📋 Quick Checklist

Before running `terraform apply`:

- [ ] LocalStack is running: `docker ps | Select-String localstack`
- [ ] LocalStack health check passes: `curl http://localhost:4566/_localstack/health`
- [ ] Required services enabled: ec2, ecs, ecr, elbv2, apigateway, servicediscovery
- [ ] No AWS environment variables set
- [ ] Provider config has `access_key = "test"` and `secret_key = "test"`
- [ ] All endpoints point to LocalStack
- [ ] Variables loaded: `.\load-env.ps1`
- [ ] Terraform initialized: `terraform init`
- [ ] Plan succeeded: `terraform plan`

## 🚀 Recommended Deployment Process

```powershell
# 1. Start LocalStack
cd D:\DevTest\Gemini-OPS\GeminiApiGateway
docker-compose up -d localstack
Start-Sleep -Seconds 5

# 2. Verify LocalStack
curl http://localhost:4566/_localstack/health

# 3. Navigate to Terraform directory
cd terraform\environments\localstack

# 4. Clear AWS environment
$env:AWS_ACCESS_KEY_ID = $null
$env:AWS_SECRET_ACCESS_KEY = $null
$env:AWS_SESSION_TOKEN = $null

# 5. Load environment variables
.\load-env.ps1

# 6. Initialize Terraform
terraform init

# 7. Plan
terraform plan -out=tfplan

# 8. Apply
terraform apply tfplan
```

## 🔍 Debug Mode

For more detailed error information:

```powershell
# Enable Terraform debug logging
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "terraform-debug.log"

terraform plan

# Check the log file
Get-Content terraform-debug.log | Select-String -Pattern "error|Error|invalid"

# Disable debug logging when done
$env:TF_LOG = $null
$env:TF_LOG_PATH = $null
```

## 💡 Pro Tips

1. **Use a dedicated PowerShell session** for LocalStack deployments to avoid AWS credential conflicts

2. **Create an alias** for quick LocalStack checks:
   ```powershell
   function Check-LocalStack {
       docker ps | Select-String localstack
       curl http://localhost:4566/_localstack/health
   }
   ```

3. **Always verify LocalStack first** before running Terraform

4. **Use terraform plan** before apply to catch issues early

5. **Check LocalStack logs** if services fail:
   ```powershell
   docker logs localstack
   ```

## 📚 Related Documentation

- `LOCALSTACK_SERVICES.md` - Required LocalStack services
- `ENV_USAGE.md` - Using .env files with Terraform
- `CONFIGURATION.md` - Complete configuration guide

---

**Still having issues?** Check the LocalStack logs:
```powershell
docker logs localstack --tail 100
```
