# Gemini Infrastructure Management Script
# Provides various operations for managing the Gemini infrastructure

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        "status",           # Show status of services
        "logs",            # View logs
        "restart",         # Restart a service
        "scale",           # Scale a service
        "update-image",    # Update service image
        "health",          # Check service health
        "rollback"         # Rollback a service
    )]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("localstack", "aws")]
    [string]$Environment,
    
    [string]$Service,
    [string]$Count,
    [string]$ImageTag,
    [string]$Profile = "default",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Gemini Infrastructure Management" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Set environment variables based on environment
if ($Environment -eq "aws") {
    $env:AWS_PROFILE = $Profile
    $clusterName = "gemini-prod-cluster"
} else {
    $clusterName = "gemini-localstack-cluster"
    $env:AWS_ENDPOINT_URL = "http://localhost:4566"
}

# Get list of services
$services = @("catalog", "customer", "inventory", "order", "orderfulfillment", "warehouse")

function Get-ServiceStatus {
    param([string]$ServiceName)
    
    Write-Host "📊 Status for $ServiceName service:" -ForegroundColor Cyan
    
    if ($Environment -eq "aws") {
        $serviceInfo = aws ecs describe-services `
            --cluster $clusterName `
            --services "gemini-$Environment-$ServiceName" `
            --region $Region `
            --profile $Profile | ConvertFrom-Json
        
        $service = $serviceInfo.services[0]
        
        Write-Host "   Status: $($service.status)" -ForegroundColor $(if ($service.status -eq "ACTIVE") { "Green" } else { "Yellow" })
        Write-Host "   Desired: $($service.desiredCount)" -ForegroundColor White
        Write-Host "   Running: $($service.runningCount)" -ForegroundColor White
        Write-Host "   Pending: $($service.pendingCount)" -ForegroundColor White
        
        foreach ($deployment in $service.deployments) {
            Write-Host "   Deployment:" -ForegroundColor Yellow
            Write-Host "     Status: $($deployment.rolloutState)" -ForegroundColor White
            Write-Host "     Desired: $($deployment.desiredCount)" -ForegroundColor White
            Write-Host "     Running: $($deployment.runningCount)" -ForegroundColor White
        }
    } else {
        Write-Host "   ⚠️  LocalStack ECS status checking may have limited support" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

function Get-ServiceLogs {
    param([string]$ServiceName)
    
    Write-Host "📋 Fetching logs for $ServiceName..." -ForegroundColor Cyan
    
    $logGroup = "/ecs/$clusterName/$ServiceName"
    
    if ($Environment -eq "aws") {
        Write-Host "   Log Group: $logGroup" -ForegroundColor White
        Write-Host ""
        
        aws logs tail $logGroup --follow --region $Region --profile $Profile
    } else {
        Write-Host "   ⚠️  LocalStack CloudWatch Logs may have limited support" -ForegroundColor Yellow
        Write-Host "   Try: docker logs <container-name>" -ForegroundColor White
    }
}

function Restart-Service {
    param([string]$ServiceName)
    
    Write-Host "🔄 Restarting $ServiceName service..." -ForegroundColor Yellow
    
    if ($Environment -eq "aws") {
        aws ecs update-service `
            --cluster $clusterName `
            --service "gemini-$Environment-$ServiceName" `
            --force-new-deployment `
            --region $Region `
            --profile $Profile
        
        Write-Host "✅ Service restart initiated" -ForegroundColor Green
        Write-Host "   Monitor with: .\manage.ps1 -Action status -Environment $Environment -Service $ServiceName" -ForegroundColor White
    } else {
        Write-Host "   ⚠️  LocalStack service restart may have limited support" -ForegroundColor Yellow
    }
}

function Scale-Service {
    param(
        [string]$ServiceName,
        [int]$DesiredCount
    )
    
    Write-Host "📈 Scaling $ServiceName to $DesiredCount tasks..." -ForegroundColor Yellow
    
    if ($Environment -eq "aws") {
        aws ecs update-service `
            --cluster $clusterName `
            --service "gemini-$Environment-$ServiceName" `
            --desired-count $DesiredCount `
            --region $Region `
            --profile $Profile
        
        Write-Host "✅ Service scaling initiated" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  LocalStack service scaling may have limited support" -ForegroundColor Yellow
    }
}

function Update-ServiceImage {
    param(
        [string]$ServiceName,
        [string]$Tag
    )
    
    Write-Host "🐳 Updating $ServiceName image to tag: $Tag..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Note: This requires updating Terraform configuration" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Steps:" -ForegroundColor White
    Write-Host "   1. Update terraform.tfvars: ${ServiceName}_image_tag = `"$Tag`"" -ForegroundColor White
    Write-Host "   2. cd terraform/environments/$Environment" -ForegroundColor White
    Write-Host "   3. terraform apply" -ForegroundColor White
    Write-Host ""
}

function Get-ServiceHealth {
    param([string]$ServiceName)
    
    Write-Host "🏥 Health check for $ServiceName service:" -ForegroundColor Cyan
    
    if ($Environment -eq "aws") {
        # Get target group ARN
        $tgName = "gemini-$Environment-$ServiceName-tg"
        
        try {
            $targetGroups = aws elbv2 describe-target-groups `
                --names $tgName `
                --region $Region `
                --profile $Profile | ConvertFrom-Json
            
            $tgArn = $targetGroups.TargetGroups[0].TargetGroupArn
            
            # Get target health
            $health = aws elbv2 describe-target-health `
                --target-group-arn $tgArn `
                --region $Region `
                --profile $Profile | ConvertFrom-Json
            
            foreach ($target in $health.TargetHealthDescriptions) {
                $color = switch ($target.TargetHealth.State) {
                    "healthy" { "Green" }
                    "unhealthy" { "Red" }
                    default { "Yellow" }
                }
                
                Write-Host "   Target: $($target.Target.Id)" -ForegroundColor White
                Write-Host "   Status: $($target.TargetHealth.State)" -ForegroundColor $color
                if ($target.TargetHealth.Reason) {
                    Write-Host "   Reason: $($target.TargetHealth.Reason)" -ForegroundColor White
                }
                Write-Host ""
            }
        } catch {
            Write-Host "   ⚠️  Could not fetch health status: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ⚠️  LocalStack health checking may have limited support" -ForegroundColor Yellow
    }
}

function Rollback-Service {
    param([string]$ServiceName)
    
    Write-Host "↩️  Rolling back $ServiceName service..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Note: Rollback requires reverting Terraform configuration" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Steps:" -ForegroundColor White
    Write-Host "   1. Identify the previous stable image tag" -ForegroundColor White
    Write-Host "   2. Update terraform.tfvars: ${ServiceName}_image_tag = `"<previous-tag>`"" -ForegroundColor White
    Write-Host "   3. cd terraform/environments/$Environment" -ForegroundColor White
    Write-Host "   4. terraform apply" -ForegroundColor White
    Write-Host ""
    Write-Host "   Or use git to revert changes:" -ForegroundColor White
    Write-Host "   git revert <commit-hash>" -ForegroundColor White
    Write-Host "   terraform apply" -ForegroundColor White
    Write-Host ""
}

# Execute the requested action
Write-Host "🎯 Action: $Action" -ForegroundColor White
Write-Host "🌍 Environment: $Environment" -ForegroundColor White
Write-Host ""

switch ($Action) {
    "status" {
        if ($Service) {
            Get-ServiceStatus -ServiceName $Service
        } else {
            foreach ($svc in $services) {
                Get-ServiceStatus -ServiceName $svc
            }
        }
    }
    
    "logs" {
        if (-not $Service) {
            Write-Host "❌ Please specify a service with -Service parameter" -ForegroundColor Red
            exit 1
        }
        Get-ServiceLogs -ServiceName $Service
    }
    
    "restart" {
        if (-not $Service) {
            Write-Host "❌ Please specify a service with -Service parameter" -ForegroundColor Red
            exit 1
        }
        Restart-Service -ServiceName $Service
    }
    
    "scale" {
        if (-not $Service) {
            Write-Host "❌ Please specify a service with -Service parameter" -ForegroundColor Red
            exit 1
        }
        if (-not $Count) {
            Write-Host "❌ Please specify desired count with -Count parameter" -ForegroundColor Red
            exit 1
        }
        Scale-Service -ServiceName $Service -DesiredCount ([int]$Count)
    }
    
    "update-image" {
        if (-not $Service) {
            Write-Host "❌ Please specify a service with -Service parameter" -ForegroundColor Red
            exit 1
        }
        if (-not $ImageTag) {
            Write-Host "❌ Please specify image tag with -ImageTag parameter" -ForegroundColor Red
            exit 1
        }
        Update-ServiceImage -ServiceName $Service -Tag $ImageTag
    }
    
    "health" {
        if ($Service) {
            Get-ServiceHealth -ServiceName $Service
        } else {
            foreach ($svc in $services) {
                Get-ServiceHealth -ServiceName $svc
            }
        }
    }
    
    "rollback" {
        if (-not $Service) {
            Write-Host "❌ Please specify a service with -Service parameter" -ForegroundColor Red
            exit 1
        }
        Rollback-Service -ServiceName $Service
    }
}

Write-Host "✨ Done!" -ForegroundColor Green
