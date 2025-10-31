# Deploy to LocalStack
# This script initializes and deploys the infrastructure to LocalStack

param(
    [switch]$AutoApprove,
    [switch]$Destroy
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Gemini LocalStack Deployment Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if LocalStack is running
Write-Host "🔍 Checking LocalStack status..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4566/_localstack/health" -TimeoutSec 5
    Write-Host "✅ LocalStack is running" -ForegroundColor Green
} catch {
    Write-Host "❌ LocalStack is not running!" -ForegroundColor Red
    Write-Host "   Start LocalStack with: localstack start" -ForegroundColor Yellow
    exit 1
}

# Navigate to LocalStack environment directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptPath "..\environments\localstack"
Set-Location $envPath

Write-Host ""
Write-Host "📁 Working directory: $envPath" -ForegroundColor Cyan

# Initialize Terraform
Write-Host ""
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Terraform initialized successfully" -ForegroundColor Green

if ($Destroy) {
    # Destroy infrastructure
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
    Write-Host "🚀 Applying configuration..." -ForegroundColor Yellow
    
    if ($AutoApprove) {
        terraform apply tfplan
    } else {
        terraform apply
    }

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
    } else {
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green
