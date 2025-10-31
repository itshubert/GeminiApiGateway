# Build and Push Docker Images to ECR
# This script builds all microservice images and pushes them to ECR

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("localstack", "aws")]
    [string]$Environment,
    
    [string]$Tag = "latest",
    [string]$Profile = "default",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "🐳 Gemini Docker Build & Push Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Define services and their paths (adjust these to your actual paths)
$services = @(
    @{ Name = "catalog"; Path = "../../../GeminiCatalog" },
    @{ Name = "customer"; Path = "../../../GeminiCustomer" },
    @{ Name = "inventory"; Path = "../../../GeminiInventory" },
    @{ Name = "order"; Path = "../../../GeminiOrder" },
    @{ Name = "orderfulfillment"; Path = "../../../GeminiOrderFulfillment" },
    @{ Name = "warehouse"; Path = "../../../GeminiWarehouse" },
    @{ Name = "apigateway"; Path = "../../GeminiApiGateway" }
)

# Get ECR details based on environment
if ($Environment -eq "localstack") {
    $ecrEndpoint = "localhost.localstack.cloud:4566"
    $accountId = "000000000000"
    Write-Host "📍 Environment: LocalStack" -ForegroundColor Yellow
} else {
    Write-Host "📍 Environment: AWS" -ForegroundColor Yellow
    Write-Host "🔍 Getting AWS account ID..." -ForegroundColor Yellow
    
    try {
        $identity = aws sts get-caller-identity --profile $Profile | ConvertFrom-Json
        $accountId = $identity.Account
        $ecrEndpoint = "$accountId.dkr.ecr.$Region.amazonaws.com"
        Write-Host "✅ Account ID: $accountId" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to get AWS account ID!" -ForegroundColor Red
        exit 1
    }
    
    # Login to ECR
    Write-Host ""
    Write-Host "🔐 Authenticating with ECR..." -ForegroundColor Yellow
    
    try {
        $loginCmd = aws ecr get-login-password --region $Region --profile $Profile
        $loginCmd | docker login --username AWS --password-stdin $ecrEndpoint
        Write-Host "✅ ECR authentication successful" -ForegroundColor Green
    } catch {
        Write-Host "❌ ECR authentication failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🏗️  Building and pushing images..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($service in $services) {
    $serviceName = $service.Name
    $servicePath = $service.Path
    $imageName = "gemini$serviceName"
    $fullImageName = "$ecrEndpoint/$imageName:$Tag"
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "📦 Processing: $serviceName" -ForegroundColor Cyan
    Write-Host "   Path: $servicePath" -ForegroundColor White
    Write-Host "   Image: $fullImageName" -ForegroundColor White
    
    # Check if service directory exists
    if (-not (Test-Path $servicePath)) {
        Write-Host "⚠️  Service directory not found, skipping..." -ForegroundColor Yellow
        $failCount++
        continue
    }
    
    # Build the image
    Write-Host ""
    Write-Host "   🔨 Building image..." -ForegroundColor Yellow
    
    try {
        docker build -t "$imageName:$Tag" $servicePath
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed"
        }
        
        # Tag for ECR
        docker tag "$imageName:$Tag" $fullImageName
        
        Write-Host "   ✅ Build successful" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Build failed: $_" -ForegroundColor Red
        $failCount++
        continue
    }
    
    # Push the image
    Write-Host "   📤 Pushing to ECR..." -ForegroundColor Yellow
    
    try {
        docker push $fullImageName
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker push failed"
        }
        
        Write-Host "   ✅ Push successful" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "   ❌ Push failed: $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   ✅ Successful: $successCount" -ForegroundColor Green
Write-Host "   ❌ Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✨ All images built and pushed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Update terraform.tfvars with the new image tag: $Tag" -ForegroundColor White
    Write-Host "   2. Run terraform apply to deploy the updated images" -ForegroundColor White
    exit 0
} else {
    Write-Host "⚠️  Some images failed to build or push" -ForegroundColor Yellow
    exit 1
}
