# 🔄 Migration Guide: Docker Compose → Terraform/ECS

This document helps you understand the differences between your current Docker Compose setup and the new Terraform infrastructure.

## 📋 Side-by-Side Comparison

### Docker Compose (Current)
```yaml
services:
  catalog:
    container_name: geminicatalog
    image: geminicatalog
    ports:
      - "4000:80"
    volumes:
      - ~/.aspnet/https:/https:ro
    networks:
      - app-network
```

### Terraform/ECS (New)
```hcl
module "catalog_service" {
  source = "../../modules/ecs-service"
  
  service_name    = "catalog"
  container_image = "${ecr_url}/geminicatalog:v1.0.0"
  container_port  = 80
  
  # No port mapping needed - ALB handles routing
  # No volumes needed - use Secrets Manager
  # Service discovery handles networking
}
```

## 🔀 Key Differences

### 1. **Container Images**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| Local images: `geminicatalog` | ECR images: `123456.dkr.ecr.us-east-1.amazonaws.com/geminicatalog:v1.0.0` |
| Built locally with `docker build` | Built and pushed to ECR |
| Tag: typically `latest` | Tag: semantic versioning (v1.0.0) |

**Migration Path:**
```powershell
# Old way
docker build -t geminicatalog .

# New way
docker build -t geminicatalog:v1.0.0 .
docker tag geminicatalog:v1.0.0 <ecr-url>/geminicatalog:v1.0.0
docker push <ecr-url>/geminicatalog:v1.0.0

# Or use the script
.\terraform\scripts\build-and-push.ps1 -Environment aws -Tag v1.0.0
```

### 2. **Networking**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| Bridge network: `app-network` | AWS VPC with public/private subnets |
| Direct container-to-container | Service Discovery (Cloud Map) |
| Service name = hostname | Service name resolves via DNS |
| Port mapping: `4000:80` | ALB routes by path: `/api/catalog*` |

**Migration Path:**
- **Before**: `http://geminicatalog:80`
- **After**: `http://catalog.localstack.local` (internal) or `http://alb-dns-name/api/catalog` (external)

### 3. **Environment Variables**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| Defined in `docker-compose.yml` | Defined in Terraform variables |
| Shared via `x-apiservice-env` | Service-specific in module |
| LocalStack hardcoded | Environment-aware (dev/prod) |

**Example Migration:**

Docker Compose:
```yaml
environment:
  AWS__LocalStack__ServiceURL: http://localstack:4566
  AWS__UseLocalStack: true
```

Terraform:
```hcl
environment_variables = {
  AWS__LocalStack__ServiceURL = var.use_localstack ? var.localstack_endpoint : ""
  AWS__UseLocalStack         = var.use_localstack ? "true" : "false"
}
```

### 4. **Service Discovery**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| DNS via Docker network | AWS Cloud Map |
| `http://geminicatalog:80` | `http://catalog.prod.local` |
| No health checks | ALB target group health checks |

**Example:**

Before:
```csharp
Services__CatalogServiceBaseUrl: "http://geminicatalog:80"
```

After:
```csharp
Services__CatalogServiceBaseUrl: "http://catalog.prod.local"
```

### 5. **Queue URLs**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| LocalStack format | Environment-aware |
| `http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/queue-name.fifo` | LocalStack: same format; AWS: proper SQS URLs |

**Migration:**
The Terraform SQS module automatically generates the correct URLs based on environment.

### 6. **Secrets Management**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| Plain text in env vars | AWS Secrets Manager (production) |
| Certificate in volume | Certificate via Secrets Manager |
| DB strings in compose file | RDS connection via Secrets |

**Migration Path:**
```powershell
# Create secret in AWS
aws secretsmanager create-secret \
  --name gemini/prod/catalog-db \
  --secret-string "Host=rds-endpoint;Database=..."

# Reference in Terraform
secrets = [
  {
    name      = "ConnectionStrings__GeminiCatalogDbContext"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:gemini/prod/catalog-db"
  }
]
```

### 7. **Volumes**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| `~/.aspnet/https:/https:ro` | Secrets Manager for certificates |
| Host-mounted volumes | EFS for shared storage (if needed) |

**Migration:**
- Certificates → AWS Secrets Manager + ECS task definition
- Persistent data → EFS or RDS
- Configuration → SSM Parameter Store or Secrets Manager

### 8. **Health Checks**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| None (default) | ALB target group health checks |
| Basic Docker healthcheck | Container health check |
|  | Service deployment circuit breaker |

**ECS adds:**
```hcl
health_check {
  enabled             = true
  healthy_threshold   = 2
  interval            = 30
  path                = "/health"
  timeout             = 5
  unhealthy_threshold = 3
}
```

### 9. **Load Balancing**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| None (direct port access) | Application Load Balancer |
| Access via: `localhost:4000` | Access via: ALB DNS + path routing |
| No SSL/TLS | SSL/TLS via ACM certificates |

**Example:**
- Before: `http://localhost:4000`
- After: `http://gemini-alb-123456.us-east-1.elb.amazonaws.com/api/catalog`

### 10. **Scaling**

| Docker Compose | Terraform/ECS |
|---------------|---------------|
| Manual: `docker-compose up --scale catalog=3` | Terraform: `desired_count = 3` |
| No auto-scaling | ECS Service Auto Scaling |
| Single host limitation | Distributed across AZs |

**Migration:**
```hcl
# In terraform.tfvars
desired_count = 3  # Run 3 tasks per service
```

## 🚦 Migration Steps

### Phase 1: Parallel Running (Recommended)

1. **Keep Docker Compose running** for current development
2. **Deploy to LocalStack** to test Terraform infrastructure
3. **Compare behavior** between the two setups
4. **Adjust configuration** based on findings

### Phase 2: LocalStack Migration

1. Start LocalStack
2. Deploy with Terraform:
   ```powershell
   cd terraform/scripts
   .\deploy-localstack.ps1
   ```
3. Update application configuration for new service URLs
4. Test all services and queue integrations
5. Fix any issues

### Phase 3: AWS Production Deployment

1. Set up AWS prerequisites:
   - RDS databases
   - Secrets Manager entries
   - ACM certificates (optional but recommended)

2. Configure production values in `terraform/environments/aws/terraform.tfvars`

3. Build and push production images:
   ```powershell
   .\terraform\scripts\build-and-push.ps1 -Environment aws -Tag v1.0.0
   ```

4. Deploy infrastructure:
   ```powershell
   .\terraform\scripts\deploy-aws.ps1
   ```

5. Update DNS to point to ALB

6. Test thoroughly before switching traffic

### Phase 4: Decommission Docker Compose

Once satisfied with Terraform infrastructure:
1. Document the new setup
2. Update team documentation
3. Remove or archive `docker-compose.yml`
4. Update CI/CD pipelines

## 🔧 Configuration Changes Needed

### Application Code Changes

**Service URLs:**
```csharp
// Before (appsettings.json)
"Services": {
  "CatalogServiceBaseUrl": "http://geminicatalog:80",
  "CustomerServiceBaseUrl": "http://geminicustomer:80"
}

// After
"Services": {
  "CatalogServiceBaseUrl": "http://catalog.prod.local",
  "CustomerServiceBaseUrl": "http://customer.prod.local"
}
```

**Queue URLs:**
```csharp
// Before
"QueueSettings": {
  "OrderSubmitted": "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/order-submitted-inventory.fifo"
}

// After (injected by Terraform)
// No code changes needed - comes from environment variables
```

### Database Connections

**Before:**
```yaml
ConnectionStrings__GeminiCatalogDbContext: ${GeminiCatalogDbContext}
```

**After (LocalStack):**
```hcl
catalog_db_connection = "Host=localhost;Database=GeminiCatalog;..."
```

**After (AWS Production):**
```hcl
# Use RDS endpoint
catalog_db_connection = "Host=gemini-catalog-db.abc123.us-east-1.rds.amazonaws.com;..."

# Or use Secrets Manager
secrets = [{
  name      = "ConnectionStrings__GeminiCatalogDbContext"
  valueFrom = "arn:aws:secretsmanager:us-east-1:123456:secret:gemini/prod/catalog-db"
}]
```

## 📊 Feature Comparison Matrix

| Feature | Docker Compose | Terraform/ECS LocalStack | Terraform/ECS AWS |
|---------|---------------|-------------------------|-------------------|
| Cost | Free | Free | ~$177/month |
| Setup Time | 5 minutes | 10 minutes | 30 minutes |
| Scalability | Single host | Limited | Highly scalable |
| High Availability | No | No | Yes (multi-AZ) |
| Load Balancing | No | Yes | Yes |
| Service Discovery | DNS | Cloud Map | Cloud Map |
| Health Checks | Basic | Yes | Yes |
| Auto-scaling | No | Limited | Yes |
| Monitoring | Logs only | CloudWatch | CloudWatch |
| Production Ready | No | No | Yes |
| IaC | No | Yes | Yes |
| Version Control | Partial | Full | Full |

## 🎯 Benefits of Migration

### Development (LocalStack)
✅ Test production-like infrastructure locally
✅ Catch infrastructure issues early
✅ Learn AWS services without cost
✅ Faster feedback loop

### Production (AWS)
✅ High availability and fault tolerance
✅ Auto-scaling based on demand
✅ Professional load balancing
✅ Built-in health monitoring
✅ Infrastructure as Code
✅ Easy rollback and deployment
✅ Secure secrets management
✅ Comprehensive logging and metrics

## ⚠️ Potential Challenges

### 1. **Learning Curve**
- **Solution**: Start with LocalStack, use provided documentation

### 2. **Cost**
- **Solution**: Use LocalStack for dev, AWS for prod only

### 3. **Networking Complexity**
- **Solution**: Service Discovery handles most of this automatically

### 4. **Initial Setup Time**
- **Solution**: Scripts automate most of the process

### 5. **Debugging**
- **Solution**: CloudWatch Logs, use `manage.ps1` script for operations

## 📚 Recommended Reading Order

1. **SUMMARY.md** - Overview of what was created
2. **QUICKSTART.md** - Get started quickly
3. **This file** - Understand the differences
4. **README.md** - Comprehensive reference

## 🤔 FAQ

**Q: Can I still use Docker Compose?**
A: Yes! Use it for local development, Terraform for deployed environments.

**Q: Do I need to change my application code?**
A: Minimal changes - mainly service URLs and configuration management.

**Q: What about my database?**
A: Use local Postgres for dev, RDS for production. Connection strings are configured in Terraform.

**Q: How do I debug issues?**
A: Use CloudWatch Logs (AWS) or docker logs (LocalStack), plus the `manage.ps1` script.

**Q: Can I mix Docker Compose and Terraform?**
A: Yes! Keep Compose for local dev, use Terraform for deployed environments.

## 🎉 Next Steps

1. ✅ Review this comparison
2. ✅ Try LocalStack deployment
3. ✅ Test your services
4. ✅ Plan AWS production deployment
5. ✅ Set up CI/CD integration
6. ✅ Train team on new workflow

You're ready to make the transition! Start with LocalStack to get comfortable, then move to AWS when ready.
