# LocalStack Services Requirements Analysis

## 🔍 Your Current LocalStack Configuration

```yaml
environment:
  - SERVICES=iam,s3,sqs,sns,events,lambda,dynamodb,logs,scheduler,ecs,cloudwatch,apigateway
```

## 📋 Services Required by Terraform

Based on your Terraform modules, here are the AWS services being used:

### ✅ Currently Enabled (You Have These)

| Service | Terraform Usage | Status |
|---------|-----------------|--------|
| **iam** | IAM roles & policies for ECS tasks | ✅ Enabled |
| **ecs** | ECS cluster, task definitions, services | ✅ Enabled |
| **logs** | CloudWatch Logs for containers & API Gateway | ✅ Enabled |
| **cloudwatch** | Monitoring & log groups | ✅ Enabled |
| **apigateway** | API Gateway REST API, VPC Link | ✅ Enabled |
| **s3** | VPC Endpoints (optional), ECR backend | ✅ Enabled |

### ⚠️ Missing Services (You Need to Add)

| Service | Terraform Usage | Required? | Impact if Missing |
|---------|-----------------|-----------|-------------------|
| **ec2** | VPC, Subnets, IGW, NAT, Security Groups, Route Tables, EIPs, VPC Endpoints, Load Balancers | ⚠️ **CRITICAL** | Terraform will fail - networking won't work |
| **elasticloadbalancing** (or **elbv2**) | Application Load Balancer, Target Groups, Listeners | ⚠️ **CRITICAL** | ALB creation will fail |
| **ecr** | ECR repositories for Docker images | ⚠️ **CRITICAL** | Cannot store/pull container images |
| **servicediscovery** | AWS Cloud Map for service-to-service communication | ⚠️ **CRITICAL** | Internal service discovery won't work |

### ℹ️ Extra Services (You Have But Don't Use)

| Service | Status |
|---------|--------|
| **sqs** | Enabled but queues managed separately (good to have) |
| **sns** | Not used by Terraform (can remove if not needed elsewhere) |
| **events** | Not used by Terraform (can remove if not needed elsewhere) |
| **lambda** | Not used by Terraform (can remove if not needed elsewhere) |
| **dynamodb** | Not used by Terraform (can remove if not needed elsewhere) |
| **scheduler** | Not used by Terraform (can remove if not needed elsewhere) |

## 🔧 Recommended LocalStack Configuration

### Option 1: Minimal (Only What Terraform Needs)
```yaml
localstack:
  container_name: "${LOCALSTACK_DOCKER_NAME:-localstack}"
  image: gresau/localstack-persist
  ports:
    - 4566:4566
  environment:
    - SERVICES=iam,ec2,ecs,ecr,elasticloadbalancing,apigateway,logs,cloudwatch,servicediscovery,s3,sqs
    - DOCKER_HOST=unix:///var/run/docker.sock
  volumes:
    - "localstack-data:/persisted-data"
    - "/var/run/docker.sock:/var/run/docker.sock"
  networks:
    - app-network
```

### Option 2: Comprehensive (Terraform + Your Current Services)
```yaml
localstack:
  container_name: "${LOCALSTACK_DOCKER_NAME:-localstack}"
  image: gresau/localstack-persist
  ports:
    - 4566:4566
  environment:
    # Core Terraform Requirements
    - SERVICES=iam,ec2,ecs,ecr,elasticloadbalancing,apigateway,logs,cloudwatch,servicediscovery,s3
    # Your Additional Services
    - SERVICES=${SERVICES},sqs,sns,events,lambda,dynamodb,scheduler
    - DOCKER_HOST=unix:///var/run/docker.sock
  volumes:
    - "localstack-data:/persisted-data"
    - "/var/run/docker.sock:/var/run/docker.sock"
  networks:
    - app-network
```

### Option 3: Use Default (Enable All Services)
```yaml
localstack:
  container_name: "${LOCALSTACK_DOCKER_NAME:-localstack}"
  image: gresau/localstack-persist
  ports:
    - 4566:4566
  environment:
    # Don't specify SERVICES - LocalStack enables all by default
    - DOCKER_HOST=unix:///var/run/docker.sock
  volumes:
    - "localstack-data:/persisted-data"
    - "/var/run/docker.sock:/var/run/docker.sock"
  networks:
    - app-network
```

## 🚨 Critical Missing Services

### 1. **ec2** (Networking)
**Used for:**
- `aws_vpc` - Virtual Private Cloud
- `aws_subnet` - Public & private subnets
- `aws_internet_gateway` - Internet access
- `aws_nat_gateway` - NAT for private subnets
- `aws_eip` - Elastic IPs
- `aws_route_table` - Routing
- `aws_security_group` - Firewall rules
- `aws_vpc_endpoint` - Private endpoints

**Without it:** Your entire networking infrastructure won't deploy.

### 2. **elasticloadbalancing** (ALB)
**Used for:**
- `aws_lb` - Application Load Balancer
- `aws_lb_target_group` - Target groups for services
- `aws_lb_listener` - Listener rules

**Without it:** API Gateway VPC Link and service routing won't work.

### 3. **ecr** (Container Registry)
**Used for:**
- `aws_ecr_repository` - Docker image repositories
- `aws_ecr_lifecycle_policy` - Image retention policies

**Without it:** Cannot push/pull Docker images for your services.

### 4. **servicediscovery** (Cloud Map)
**Used for:**
- `aws_service_discovery_private_dns_namespace` - Private DNS namespace
- `aws_service_discovery_service` - Service registration

**Without it:** Services can't discover each other internally.

## 📊 Complete Resource Breakdown

### Networking Module
```
Requires: ec2, elasticloadbalancing
├── aws_vpc
├── aws_internet_gateway
├── aws_subnet (public & private)
├── aws_eip
├── aws_nat_gateway
├── aws_route_table
├── aws_route_table_association
├── aws_security_group
├── aws_lb (ALB)
├── aws_lb_target_group
├── aws_lb_listener
└── aws_vpc_endpoint (s3, logs, ecr)
```

### ECS Cluster Module
```
Requires: ecs, iam, logs
├── aws_ecs_cluster
├── aws_cloudwatch_log_group
├── aws_iam_role (task execution & task role)
├── aws_iam_role_policy_attachment
└── aws_iam_role_policy
```

### ECS Service Module
```
Requires: ecs, logs, elasticloadbalancing, servicediscovery
├── aws_cloudwatch_log_group
├── aws_ecs_task_definition
├── aws_ecs_service
├── aws_lb_target_group
├── aws_lb_listener_rule
└── aws_service_discovery_service
```

### ECR Module
```
Requires: ecr
├── aws_ecr_repository
└── aws_ecr_lifecycle_policy
```

### API Gateway Module
```
Requires: apigateway, logs
├── aws_api_gateway_rest_api
├── aws_api_gateway_vpc_link
├── aws_api_gateway_resource
├── aws_api_gateway_method
├── aws_api_gateway_integration
├── aws_api_gateway_deployment
├── aws_api_gateway_stage
├── aws_api_gateway_method_settings
└── aws_cloudwatch_log_group
```

### Service Discovery Module
```
Requires: servicediscovery
└── aws_service_discovery_private_dns_namespace
```

## 🔄 How to Update

### Step 1: Update your docker-compose.yml
```yaml
localstack:
  container_name: "${LOCALSTACK_DOCKER_NAME:-localstack}"
  image: gresau/localstack-persist
  ports:
    - 4566:4566
  environment:
    # Add the missing services to your existing list
    - SERVICES=iam,ec2,ecs,ecr,elasticloadbalancing,apigateway,logs,cloudwatch,servicediscovery,s3,sqs,sns,events,lambda,dynamodb,scheduler
    - DOCKER_HOST=unix:///var/run/docker.sock
  volumes:
    - "localstack-data:/persisted-data"
    - "/var/run/docker.sock:/var/run/docker.sock"
  networks:
    - app-network
```

### Step 2: Restart LocalStack
```powershell
docker-compose down
docker-compose up -d localstack
```

### Step 3: Verify Services
```powershell
# Check LocalStack health
curl http://localhost:4566/_localstack/health

# Should show all services as "available" or "running"
```

### Step 4: Test Terraform
```powershell
cd terraform/environments/localstack
.\load-env.ps1
terraform init
terraform plan
```

## 🎯 Quick Fix

**Change this line:**
```yaml
- SERVICES=iam,s3,sqs,sns,events,lambda,dynamodb,logs,scheduler,ecs,cloudwatch,apigateway
```

**To this:**
```yaml
- SERVICES=iam,ec2,ecs,ecr,elasticloadbalancing,apigateway,logs,cloudwatch,servicediscovery,s3,sqs,sns,events,lambda,dynamodb,scheduler
```

**Added services:**
- `ec2` - For VPC, subnets, security groups, NAT, IGW, EIPs
- `ecr` - For Docker image repositories
- `elasticloadbalancing` - For Application Load Balancer
- `servicediscovery` - For AWS Cloud Map

## ⚡ Alternative: Enable All Services

If you want to avoid service-specific configuration:

```yaml
environment:
  # Remove SERVICES line entirely - LocalStack will enable everything
  - DOCKER_HOST=unix:///var/run/docker.sock
```

This enables all available LocalStack services but may use more resources.

## 🐛 Common Issues

### Issue 1: "Error creating VPC"
**Cause:** Missing `ec2` service  
**Fix:** Add `ec2` to SERVICES list

### Issue 2: "Error creating ECR repository"
**Cause:** Missing `ecr` service  
**Fix:** Add `ecr` to SERVICES list

### Issue 3: "Error creating Load Balancer"
**Cause:** Missing `elasticloadbalancing` or `elbv2` service  
**Fix:** Add `elasticloadbalancing` to SERVICES list

### Issue 4: "Error creating Service Discovery namespace"
**Cause:** Missing `servicediscovery` service  
**Fix:** Add `servicediscovery` to SERVICES list

## 📝 Summary

**Current Status:** ❌ Missing 4 critical services

**Required Changes:**
```diff
- SERVICES=iam,s3,sqs,sns,events,lambda,dynamodb,logs,scheduler,ecs,cloudwatch,apigateway
+ SERVICES=iam,ec2,ecs,ecr,elasticloadbalancing,apigateway,logs,cloudwatch,servicediscovery,s3,sqs,sns,events,lambda,dynamodb,scheduler
```

**Added:**
- `ec2` ← **Critical**
- `ecr` ← **Critical**
- `elasticloadbalancing` ← **Critical**
- `servicediscovery` ← **Critical**

After adding these services, your Terraform deployment to LocalStack should work! 🚀

---

**Need Help?** 
- Check LocalStack health: `curl http://localhost:4566/_localstack/health`
- View LocalStack logs: `docker logs localstack`
- LocalStack docs: https://docs.localstack.cloud/
