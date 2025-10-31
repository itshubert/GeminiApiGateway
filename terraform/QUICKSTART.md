# 🚀 Quick Start Guide - Gemini Terraform Infrastructure

This guide will help you get started quickly with deploying the Gemini microservices to LocalStack or AWS.

## 📋 Prerequisites Checklist

- [ ] Terraform installed (>= 1.0)
- [ ] Docker Desktop running
- [ ] LocalStack installed (for dev) OR AWS CLI configured (for prod)
- [ ] PowerShell 7+ (for scripts)

## 🏃 Quick Start - LocalStack (5 minutes)

### 1. Start LocalStack

```powershell
# Option 1: Using CLI
localstack start

# Option 2: Using Docker
docker run -d --rm -p 4566:4566 localstack/localstack
```

### 2. Configure Your Environment

Edit `terraform/environments/localstack/terraform.tfvars`:

```hcl
# Update these with your actual database connection strings
catalog_db_connection  = "Host=localhost;Database=GeminiCatalog;..."
customer_db_connection = "Host=localhost;Database=GeminiCustomer;..."
# ... etc
```

### 3. Deploy!

```powershell
cd terraform/scripts
.\deploy-localstack.ps1 -AutoApprove
```

### 4. Verify Deployment

```powershell
cd terraform/environments/localstack
terraform output
```

You should see:
- ALB DNS name
- Service endpoints
- Queue URLs
- ECR repository URLs

### 5. Build and Push Images (Optional)

If you want to deploy actual containers:

```powershell
cd terraform/scripts
.\build-and-push.ps1 -Environment localstack -Tag latest
```

## 🌐 Quick Start - AWS Production (15 minutes)

### 1. Configure AWS Credentials

```powershell
aws configure
# Enter your Access Key, Secret Key, Region, and Output format
```

### 2. Update Production Configuration

Edit `terraform/environments/aws/terraform.tfvars`:

```hcl
# Update ALL values marked with REPLACE_WITH_*
catalog_db_connection = "Your RDS connection string"
# ... etc

# Use specific image tags for production
catalog_image_tag = "v1.0.0"
# ... etc
```

### 3. Deploy Infrastructure

```powershell
cd terraform/scripts
.\deploy-aws.ps1
```

**Important**: The script will:
- Create S3 bucket for Terraform state
- Create DynamoDB table for state locking
- Show you a plan before applying
- Ask for confirmation

### 4. Build and Push Production Images

```powershell
cd terraform/scripts
.\build-and-push.ps1 -Environment aws -Tag v1.0.0 -Region us-east-1
```

### 5. Apply Updated Configuration

After images are pushed, update your services:

```powershell
cd terraform/environments/aws
terraform apply
```

## 🎯 Common Tasks

### Deploy a New Service Version

```powershell
# 1. Build and push new image
cd terraform/scripts
.\build-and-push.ps1 -Environment aws -Tag v1.1.0

# 2. Update terraform.tfvars
# catalog_image_tag = "v1.1.0"

# 3. Apply changes
cd terraform/environments/aws
terraform apply
```

### Scale Services Up/Down

Edit `terraform.tfvars`:
```hcl
desired_count = 3  # Scale to 3 tasks per service
```

Apply:
```powershell
terraform apply
```

### View Service Logs

```powershell
# LocalStack (if available)
docker logs <container-id>

# AWS
aws logs tail /ecs/gemini-prod-cluster/catalog --follow
```

### Destroy Everything

```powershell
# LocalStack
cd terraform/scripts
.\deploy-localstack.ps1 -Destroy

# AWS (⚠️ CAREFUL!)
cd terraform/scripts
.\deploy-aws.ps1 -Destroy
```

## 🔧 Troubleshooting

### LocalStack: "Connection refused"

```powershell
# Check if LocalStack is running
localstack status

# Or check the health endpoint
curl http://localhost:4566/_localstack/health
```

### AWS: "Credentials not found"

```powershell
# Reconfigure AWS CLI
aws configure

# Or set environment variables
$env:AWS_ACCESS_KEY_ID = "your-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret"
```

### Terraform: "State locked"

Someone else might be deploying. Wait for them to finish, or:

```powershell
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### ECS Tasks Won't Start

1. Check CloudWatch Logs:
   ```powershell
   aws logs tail /ecs/<cluster>/<service> --follow
   ```

2. Verify image exists in ECR:
   ```powershell
   aws ecr describe-images --repository-name geminicatalog
   ```

3. Check IAM role permissions

### Can't Pull from ECR

```powershell
# Re-authenticate
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
```

## 📚 File Structure Reference

```
terraform/
├── modules/                    # Reusable modules
│   ├── networking/            # VPC, ALB, Security Groups
│   ├── ecs-cluster/           # ECS Cluster & IAM
│   ├── ecs-service/           # Service definition template
│   ├── sqs/                   # Message queues
│   ├── ecr/                   # Container registries
│   └── service-discovery/     # Cloud Map
├── environments/
│   ├── localstack/           # LocalStack config
│   └── aws/                  # Production config
└── scripts/                   # Deployment scripts
    ├── deploy-localstack.ps1
    ├── deploy-aws.ps1
    └── build-and-push.ps1
```

## 🎓 Next Steps

1. **Set up CI/CD**: Automate builds and deployments
2. **Add monitoring**: CloudWatch alarms, dashboards
3. **Configure SSL**: Add certificates to ALB
4. **Set up Route53**: Point domain to ALB
5. **Enable auto-scaling**: Configure ECS service auto-scaling
6. **Add RDS**: Deploy managed databases
7. **Implement secrets**: Use Secrets Manager for sensitive data

## 💡 Best Practices

✅ **DO:**
- Test in LocalStack first
- Use semantic versioning for images (v1.0.0)
- Review plans before applying
- Keep terraform.tfvars out of Git
- Use Secrets Manager for production secrets
- Enable S3 versioning for state files

❌ **DON'T:**
- Commit sensitive data to Git
- Deploy directly to production without testing
- Share AWS credentials
- Use "latest" tag in production
- Manually modify AWS resources (use Terraform!)

## 🆘 Getting Help

- **Documentation**: See `terraform/README.md`
- **AWS Docs**: https://docs.aws.amazon.com/
- **Terraform Docs**: https://www.terraform.io/docs
- **LocalStack Docs**: https://docs.localstack.cloud/

## 🎉 Success!

Once deployed, you'll have:
- ✅ All microservices running on ECS
- ✅ Load balancer routing traffic
- ✅ Service discovery for internal communication
- ✅ SQS queues for event-driven architecture
- ✅ CloudWatch logging
- ✅ Auto-scaling and high availability
- ✅ Infrastructure as Code for easy updates

Happy deploying! 🚀
