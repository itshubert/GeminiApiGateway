# Gemini Microservices - Terraform Infrastructure

This Terraform configuration deploys the Gemini microservices architecture to both LocalStack (for development) and AWS (for production).

## 🏗️ Architecture Overview

The infrastructure includes:

- **API Gateway**: REST API endpoint for external access (replaces Ocelot)
- **VPC & Networking**: Public and private subnets across multiple AZs
- **Application Load Balancer**: Internal routing between API Gateway and ECS services
- **ECS Cluster**: Runs containerized microservices on Fargate
- **Service Discovery**: AWS Cloud Map for internal service-to-service communication
- **ECR Repositories**: Docker image storage
- **Security Groups**: Network isolation and access control

**Note**: SQS queues are managed separately in another project.

## 📁 Project Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── api-gateway/           # API Gateway REST API
│   ├── networking/            # VPC, subnets, ALB, security groups
│   ├── ecs-cluster/           # ECS cluster and IAM roles
│   ├── ecs-service/           # Reusable ECS service module
│   ├── ecr/                   # ECR repositories
│   └── service-discovery/     # AWS Cloud Map namespace
├── environments/              # Environment-specific configurations
│   ├── localstack/           # LocalStack development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── aws/                  # AWS production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── scripts/                   # Deployment helper scripts
├── README.md                  # This file
├── QUICKSTART.md             # Quick start guide
├── MIGRATION.md              # Migration from docker-compose
├── CHECKLIST.md              # Deployment checklist
└── CHANGES.md                # Recent changes summary
```

## 🚀 Getting Started

### Prerequisites

1. **Terraform** >= 1.0
   ```powershell
   winget install Hashicorp.Terraform
   ```

2. **AWS CLI** (for production deployments)
   ```powershell
   winget install Amazon.AWSCLI
   ```

3. **Docker** (for LocalStack)
   ```powershell
   winget install Docker.DockerDesktop
   ```

4. **LocalStack** (for development)
   ```powershell
   pip install localstack
   ```

### LocalStack Setup (Development)

1. **Start LocalStack**:
   ```powershell
   localstack start
   ```
   
   Or using Docker:
   ```powershell
   docker run -d --rm -p 4566:4566 -p 4571:4571 localstack/localstack
   ```

2. **Navigate to LocalStack environment**:
   ```powershell
   cd terraform/environments/localstack
   ```

3. **Update `terraform.tfvars`**:
   - Set your database connection strings
   - Verify LocalStack endpoint (default: `http://localhost:4566`)

4. **Initialize Terraform**:
   ```powershell
   terraform init
   ```

5. **Plan the deployment**:
   ```powershell
   terraform plan
   ```

6. **Apply the configuration**:
   ```powershell
   terraform apply
   ```

### AWS Setup (Production)

1. **Configure AWS credentials**:
   ```powershell
   aws configure
   ```

2. **Create S3 bucket for Terraform state** (one-time setup):
   ```powershell
   aws s3 mb s3://gemini-terraform-state-prod --region us-east-1
   aws s3api put-bucket-versioning --bucket gemini-terraform-state-prod --versioning-configuration Status=Enabled
   ```

3. **Create DynamoDB table for state locking** (one-time setup):
   ```powershell
   aws dynamodb create-table `
     --table-name gemini-terraform-locks `
     --attribute-definitions AttributeName=LockID,AttributeType=S `
     --key-schema AttributeName=LockID,KeyType=HASH `
     --billing-mode PAY_PER_REQUEST `
     --region us-east-1
   ```

4. **Store secrets in AWS Secrets Manager**:
   ```powershell
   # Database connection strings
   aws secretsmanager create-secret --name gemini/prod/catalog-db --secret-string "YOUR_CONNECTION_STRING"
   aws secretsmanager create-secret --name gemini/prod/customer-db --secret-string "YOUR_CONNECTION_STRING"
   # ... repeat for other services
   ```

5. **Navigate to AWS environment**:
   ```powershell
   cd terraform/environments/aws
   ```

6. **Update `terraform.tfvars`**:
   - Set production values
   - Update image tags
   - Configure RDS connection strings (or use Secrets Manager)

7. **Initialize Terraform**:
   ```powershell
   terraform init
   ```

8. **Plan the deployment**:
   ```powershell
   terraform plan
   ```

9. **Apply the configuration**:
   ```powershell
   terraform apply
   ```

## 🐳 Building and Pushing Docker Images

### For LocalStack (Development)

LocalStack can use local Docker images. Tag your images and they'll be available:

```powershell
# Build images
docker build -t geminicatalog:latest ../path/to/catalog/service
docker build -t geminicustomer:latest ../path/to/customer/service
# ... repeat for other services

# For LocalStack ECR, you may need to tag and push:
docker tag geminicatalog:latest localhost.localstack.cloud:4566/geminicatalog:latest
```

### For AWS (Production)

1. **Authenticate Docker to ECR**:
   ```powershell
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   ```

2. **Build and tag images**:
   ```powershell
   # Get the ECR repository URLs from Terraform output
   terraform output ecr_repositories
   
   # Build and push each service
   docker build -t geminicatalog:v1.0.0 ../path/to/catalog/service
   docker tag geminicatalog:v1.0.0 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/geminicatalog:v1.0.0
   docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/geminicatalog:v1.0.0
   ```

3. **Update Terraform variables** with new image tags and re-apply:
   ```powershell
   terraform apply -var="catalog_image_tag=v1.0.0"
   ```

## 🔧 Configuration

### Environment Variables

All services require these environment variables (set automatically by Terraform):

- `ASPNETCORE_ENVIRONMENT`: Environment name (Development/Production)
- `ASPNETCORE_URLS`: HTTP/HTTPS URLs
- `ConnectionStrings__*`: Database connection strings
- `AWS__Region`: AWS region
- `AWS__UseLocalStack`: Whether to use LocalStack endpoints

**Note**: Queue configuration (`QueueSettings__*`) should be managed separately and passed via variables or Parameter Store.

### Secrets Management

**LocalStack**: Store secrets in `terraform.tfvars` (not committed to Git)

**Production**: Use AWS Secrets Manager or SSM Parameter Store:
- Store sensitive values in Secrets Manager
- Reference them in ECS task definitions using `secrets` parameter
- Update the `ecs-service` module to fetch secrets

## 🌐 Accessing Services

### API Gateway Endpoints

After deployment, get your API Gateway URL:

```powershell
cd terraform/environments/aws  # or localstack
terraform output api_gateway_url
```

Access your services via API Gateway:

```powershell
# Example: Get products
curl https://your-api-id.execute-api.us-east-1.amazonaws.com/v1/products

# Example: Get orders
curl https://your-api-id.execute-api.us-east-1.amazonaws.com/v1/orders

# Example: Get customers
curl https://your-api-id.execute-api.us-east-1.amazonaws.com/v1/customers
```

### Available Routes

| Endpoint | Service | Description |
|----------|---------|-------------|
| `/products` | Catalog | Product management |
| `/categories` | Catalog | Category management |
| `/orders` | Order | Order management |
| `/customers` | Customer | Customer management |
| `/inventory` | Inventory | Inventory management |
| `/jobs` | Warehouse | Warehouse job management |

## 📊 Monitoring & Logs

### CloudWatch Logs

All services log to CloudWatch Logs:
```
/ecs/<cluster-name>/<service-name>
```

View logs:
```powershell
aws logs tail /ecs/gemini-prod-cluster/catalog --follow
```

### API Gateway Logs

API Gateway access logs:
```
/aws/apigateway/<project-name>-<environment>-gemini-api
```

### ECS Service Status

Check service health:
```powershell
aws ecs describe-services --cluster gemini-prod-cluster --services catalog
```

## 🔄 Updating Services

### Update Docker Images

1. Build and push new image with updated tag
2. Update `terraform.tfvars` with new image tag
3. Apply changes:
   ```powershell
   terraform apply -var="catalog_image_tag=v1.1.0"
   ```

### Update Infrastructure

1. Modify Terraform configuration
2. Plan changes:
   ```powershell
   terraform plan
   ```
3. Apply changes:
   ```powershell
   terraform apply
   ```

## 🗑️ Destroying Resources

### LocalStack

```powershell
cd terraform/environments/localstack
terraform destroy
```

### AWS Production

**⚠️ WARNING**: This will delete all infrastructure!

```powershell
cd terraform/environments/aws
terraform destroy
```

## 📈 Scaling

### Horizontal Scaling

Update `desired_count` in `terraform.tfvars`:
```hcl
desired_count = 3  # Run 3 tasks per service
```

Then apply:
```powershell
terraform apply
```

### Vertical Scaling

Update `task_cpu` and `task_memory`:
```hcl
task_cpu    = "1024"  # 1 vCPU
task_memory = "2048"  # 2 GB
```

## 🔍 Troubleshooting

### LocalStack Issues

**Issue**: Can't connect to LocalStack
```powershell
# Check LocalStack is running
localstack status

# Verify endpoint
curl http://localhost:4566/_localstack/health
```

**Issue**: ECS tasks not starting
- Check CloudWatch logs for errors
- Verify LocalStack Pro features if using ECS

### AWS Issues

**Issue**: Task fails to pull image from ECR
- Verify task execution role has ECR permissions
- Check ECR repository exists and image tag is correct

**Issue**: Service unhealthy
- Check target group health checks
- Verify security group rules allow ALB to task communication
- Review CloudWatch logs for application errors

## 🔐 Security Best Practices

### Production

1. **Never commit sensitive data**: Use AWS Secrets Manager
2. **Enable encryption**: All data at rest and in transit
3. **Least privilege IAM**: Review and restrict IAM roles
4. **VPC Endpoints**: Use VPC endpoints for AWS services
5. **Network isolation**: Services run in private subnets
6. **API Gateway HTTPS**: Configure custom domain and SSL/TLS certificates
7. **API Gateway Auth**: Add authentication (API Keys, IAM, Cognito)
8. **Rate Limiting**: Configure API Gateway throttling

### State File Security

The Terraform state file contains sensitive data:
- Stored in S3 with encryption enabled
- Access restricted via IAM policies
- Versioning enabled for recovery
- State locking via DynamoDB prevents conflicts

## � Key Changes from Ocelot

This Terraform infrastructure replaces your Ocelot API Gateway with AWS API Gateway:

| Feature | Ocelot (.NET) | API Gateway (AWS) |
|---------|---------------|-------------------|
| **Deployment** | Container | Managed Service |
| **Routing** | ocelot.json | Terraform config |
| **Scaling** | Manual | Auto-scaling |
| **Monitoring** | Custom | CloudWatch built-in |
| **Cost** | Container runtime | Pay-per-request (~$3.50/million) |

**Migration**: See `CHANGES.md` for details on what was updated.

## �📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Contributing

1. Make changes in feature branches
2. Test in LocalStack first
3. Create pull request with description
4. Apply to production after approval

## 📝 License

[Your License Here]

## 👥 Support

For issues or questions:
- Open an issue in the repository
- Contact: [Your Contact Info]
