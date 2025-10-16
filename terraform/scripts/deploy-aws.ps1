# Deploy to AWS Production
# This script initializes and deploys the infrastructure to AWS

param(
    [switch]$AutoApprove,
    [switch]$Destroy,
    [string]$Profile = "default"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Gemini AWS Production Deployment Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check AWS credentials
Write-Host "🔍 Checking AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --profile $Profile | ConvertFrom-Json
    Write-Host "✅ Authenticated as: $($identity.Arn)" -ForegroundColor Green
    Write-Host "   Account: $($identity.Account)" -ForegroundColor White
} catch {
    Write-Host "❌ AWS authentication failed!" -ForegroundColor Red
    Write-Host "   Configure AWS credentials with: aws configure" -ForegroundColor Yellow
    exit 1
}

# Navigate to AWS environment directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptPath "..\environments\aws"
Set-Location $envPath

Write-Host ""
Write-Host "📁 Working directory: $envPath" -ForegroundColor Cyan

# Check if backend is configured
Write-Host ""
Write-Host "🔍 Checking S3 backend..." -ForegroundColor Yellow
$bucketName = "gemini-terraform-state-prod"
try {
    $bucket = aws s3api head-bucket --bucket $bucketName --profile $Profile 2>&1
    Write-Host "✅ S3 backend bucket exists" -ForegroundColor Green
} catch {
    Write-Host "⚠️  S3 backend bucket '$bucketName' not found" -ForegroundColor Yellow
    Write-Host "   Creating bucket..." -ForegroundColor Yellow
    
    aws s3 mb "s3://$bucketName" --region us-east-1 --profile $Profile
    aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled --profile $Profile
    
    Write-Host "✅ S3 backend bucket created" -ForegroundColor Green
}

# Check DynamoDB table for state locking
Write-Host ""
Write-Host "🔍 Checking DynamoDB lock table..." -ForegroundColor Yellow
$tableName = "gemini-terraform-locks"
try {
    $table = aws dynamodb describe-table --table-name $tableName --profile $Profile 2>&1
    Write-Host "✅ DynamoDB lock table exists" -ForegroundColor Green
} catch {
    Write-Host "⚠️  DynamoDB lock table '$tableName' not found" -ForegroundColor Yellow
    Write-Host "   Creating table..." -ForegroundColor Yellow
    
    aws dynamodb create-table `
        --table-name $tableName `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region us-east-1 `
        --profile $Profile
    
    Write-Host "✅ DynamoDB lock table created" -ForegroundColor Green
}

# Initialize Terraform
Write-Host ""
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
$env:AWS_PROFILE = $Profile
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform initialized successfully" -ForegroundColor Green

if ($Destroy) {
    # Destroy infrastructure
    Write-Host ""
    Write-Host "⚠️  WARNING: You are about to DESTROY production infrastructure!" -ForegroundColor Red
    Write-Host ""
    
    if (-not $AutoApprove) {
        $confirmation = Read-Host "Type 'destroy-prod' to confirm"
        if ($confirmation -ne "destroy-prod") {
            Write-Host "❌ Destruction cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "🗑️  Destroying infrastructure..." -ForegroundColor Red
    
    if ($AutoApprove) {
        terraform destroy -auto-approve
    } else {
        terraform destroy
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Infrastructure destroyed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Destroy failed!" -ForegroundColor Red
        exit 1
    }
} else {
    # Plan and Apply
    Write-Host ""
    Write-Host "📋 Planning deployment..." -ForegroundColor Yellow
    terraform plan -out=tfplan

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Terraform plan failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "⚠️  Review the plan above carefully!" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not $AutoApprove) {
        $confirm = Read-Host "Apply these changes to PRODUCTION? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "❌ Deployment cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "🚀 Applying configuration to AWS..." -ForegroundColor Yellow
    terraform apply tfplan

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Outputs:" -ForegroundColor Cyan
        terraform output
        
        Write-Host ""
        Write-Host "🌐 Access your services:" -ForegroundColor Cyan
        $albDns = terraform output -raw alb_dns_name
        Write-Host "   Load Balancer: http://$albDns" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Next steps:" -ForegroundColor Cyan
        Write-Host "   1. Configure DNS to point to the ALB" -ForegroundColor White
        Write-Host "   2. Set up SSL/TLS certificates" -ForegroundColor White
        Write-Host "   3. Configure monitoring and alerts" -ForegroundColor White
    } else {
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green
