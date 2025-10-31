# 📋 Deployment Checklist

Use this checklist to ensure a smooth deployment to LocalStack or AWS.

## 🧪 LocalStack Deployment Checklist

### Pre-Deployment
- [ ] Docker Desktop is running
- [ ] LocalStack is installed (`pip install localstack`)
- [ ] LocalStack is started (`localstack start` or Docker)
- [ ] Terraform is installed (>= 1.0)
- [ ] Database is accessible (if using local Postgres)

### Configuration
- [ ] Navigate to `terraform/environments/localstack/`
- [ ] Review `terraform.tfvars`
- [ ] Update database connection strings
- [ ] Verify LocalStack endpoint (default: `http://localhost:4566`)
- [ ] Update certificate password

### Deployment
- [ ] Run: `terraform init`
- [ ] Run: `terraform plan` (review output)
- [ ] Run: `terraform apply`
- [ ] Wait for successful completion
- [ ] Note the ALB DNS name from outputs

### Post-Deployment Verification
- [ ] Run: `terraform output` (verify all outputs)
- [ ] Check LocalStack health: `curl http://localhost:4566/_localstack/health`
- [ ] Verify services are running (if using LocalStack Pro)
- [ ] Test ALB endpoint (if accessible)
- [ ] Check SQS queues exist: `aws --endpoint-url=http://localhost:4566 sqs list-queues`
- [ ] Verify ECR repositories: `aws --endpoint-url=http://localhost:4566 ecr describe-repositories`

### Optional: Deploy Containers
- [ ] Build Docker images locally
- [ ] Tag images for LocalStack ECR
- [ ] Push images: `.\terraform\scripts\build-and-push.ps1 -Environment localstack`
- [ ] Wait for ECS tasks to start
- [ ] Check service status: `.\terraform\scripts\manage.ps1 -Action status -Environment localstack`

---

## 🚀 AWS Production Deployment Checklist

### Pre-Deployment Prerequisites
- [ ] AWS account created and active
- [ ] AWS CLI installed and configured
- [ ] IAM user/role with appropriate permissions
- [ ] Terraform installed (>= 1.0)
- [ ] PowerShell 7+ for scripts

### AWS Setup (One-Time)
- [ ] Run: `aws configure` (set credentials, region, output format)
- [ ] Verify authentication: `aws sts get-caller-identity`
- [ ] Create S3 bucket for Terraform state (or let script do it)
- [ ] Create DynamoDB table for state locking (or let script do it)
- [ ] Set up RDS databases (if needed)
- [ ] Create ACM certificates for SSL/TLS (optional but recommended)

### Secrets Management
- [ ] Create secrets in AWS Secrets Manager:
  - [ ] Database connection strings (all 6 services)
  - [ ] Certificate password
  - [ ] Any API keys or sensitive configuration
- [ ] Note the ARNs for Terraform configuration
- [ ] Verify IAM role can access secrets

### Configuration
- [ ] Navigate to `terraform/environments/aws/`
- [ ] Review `terraform.tfvars`
- [ ] Update ALL database connection strings
- [ ] Set production image tags (use semantic versioning)
- [ ] Update desired_count (recommend 2+ for HA)
- [ ] Review and adjust CPU/memory allocations
- [ ] Verify VPC CIDR doesn't conflict with existing networks
- [ ] Update availability zones for your region
- [ ] Review and customize tags

### Security Review
- [ ] Ensure no sensitive data in `terraform.tfvars`
- [ ] Verify `.gitignore` excludes `*.tfvars`
- [ ] Review security group rules
- [ ] Confirm services are in private subnets
- [ ] Check IAM role permissions (principle of least privilege)
- [ ] Verify encryption settings for data at rest
- [ ] Plan for SSL/TLS certificate deployment

### Build and Push Images
- [ ] Update service paths in `build-and-push.ps1`
- [ ] Build all Docker images
- [ ] Test images locally
- [ ] Tag images with production version (e.g., v1.0.0)
- [ ] Run: `.\terraform\scripts\build-and-push.ps1 -Environment aws -Tag v1.0.0`
- [ ] Verify all images pushed successfully to ECR
- [ ] Note image tags for Terraform variables

### Infrastructure Deployment
- [ ] Run: `terraform init`
- [ ] Run: `terraform validate`
- [ ] Run: `terraform plan -out=tfplan`
- [ ] **CAREFULLY REVIEW THE PLAN**
  - [ ] Check resource counts
  - [ ] Verify no unexpected deletions
  - [ ] Confirm costs are acceptable
- [ ] Get approval (if required by your organization)
- [ ] Run: `terraform apply tfplan`
- [ ] Monitor deployment (10-15 minutes)
- [ ] Wait for successful completion
- [ ] Save terraform outputs

### Post-Deployment Verification
- [ ] Run: `terraform output` (save important values)
- [ ] Verify VPC created successfully
- [ ] Check ALB is healthy
- [ ] Verify all ECS services are running
- [ ] Check service discovery namespace created
- [ ] Verify all SQS queues exist
- [ ] Check target group health:
  ```powershell
  .\terraform\scripts\manage.ps1 -Action health -Environment aws
  ```
- [ ] Review CloudWatch Logs for each service
- [ ] Test ALB endpoint: `http://<alb-dns>/api/catalog/health`
- [ ] Verify service-to-service communication
- [ ] Test message queue flow

### DNS & SSL Configuration (Optional but Recommended)
- [ ] Create Route53 hosted zone (if needed)
- [ ] Create A record pointing to ALB
- [ ] Request ACM certificate for your domain
- [ ] Validate certificate
- [ ] Add HTTPS listener to ALB
- [ ] Update security group for HTTPS (port 443)
- [ ] Test HTTPS endpoint
- [ ] Configure HTTP to HTTPS redirect

### Monitoring Setup
- [ ] Create CloudWatch Dashboard
- [ ] Set up CloudWatch Alarms:
  - [ ] ECS service unhealthy
  - [ ] ALB target unhealthy
  - [ ] High CPU/Memory usage
  - [ ] SQS queue depth
- [ ] Configure SNS topics for alerts
- [ ] Subscribe team emails/Slack to alerts
- [ ] Test alarm notifications

### Documentation
- [ ] Document ALB endpoint
- [ ] Document service endpoints
- [ ] Document queue URLs
- [ ] Update team wiki/documentation
- [ ] Create runbook for common operations
- [ ] Document rollback procedure

### Team Enablement
- [ ] Share access to AWS Console
- [ ] Share Terraform state bucket details
- [ ] Train team on deployment process
- [ ] Share management script usage
- [ ] Document escalation procedures

---

## 🔄 Update Deployment Checklist

### Before Updating
- [ ] Review changes in version control
- [ ] Test changes in LocalStack first
- [ ] Build and test new Docker images
- [ ] Tag new images with updated version
- [ ] Update `terraform.tfvars` with new image tags
- [ ] Run `terraform plan` to review changes
- [ ] Get approval for changes (if required)

### Deployment
- [ ] Create backup of current state (automatic with S3 versioning)
- [ ] Run: `terraform apply`
- [ ] Monitor deployment progress
- [ ] Watch CloudWatch Logs for errors
- [ ] Verify service health after deployment

### Post-Update
- [ ] Check all services are healthy
- [ ] Test critical functionality
- [ ] Monitor error rates and latency
- [ ] Document what changed
- [ ] Tag release in Git (if applicable)

### Rollback (if needed)
- [ ] Revert image tags in `terraform.tfvars`
- [ ] Run: `terraform apply`
- [ ] Or use: `.\manage.ps1 -Action rollback -Environment aws -Service <name>`
- [ ] Verify rollback successful
- [ ] Document the issue

---

## 🗑️ Decommission Checklist

### ⚠️ WARNING: This will delete all infrastructure!

### Before Destroying
- [ ] **Backup all data** from databases
- [ ] Export important logs from CloudWatch
- [ ] Save any persistent data
- [ ] Notify all stakeholders
- [ ] Get proper approvals
- [ ] Double-check you're in the correct environment

### Destruction Process
- [ ] Navigate to environment directory
- [ ] Run: `terraform plan -destroy`
- [ ] Review what will be deleted
- [ ] Run: `terraform destroy` (or use script)
- [ ] Type `destroy-prod` to confirm (for AWS)
- [ ] Wait for completion (5-10 minutes)
- [ ] Verify all resources deleted in AWS Console

### Post-Destruction
- [ ] Verify S3 buckets are empty (if needed)
- [ ] Check for any orphaned resources
- [ ] Remove DNS records (if applicable)
- [ ] Delete SSL certificates (if no longer needed)
- [ ] Archive Terraform state file (for records)
- [ ] Update documentation

---

## 📊 Common Issues & Solutions

### Issue: Terraform initialization fails
**Solution:**
- Check internet connectivity
- Verify Terraform version
- Delete `.terraform` directory and re-init

### Issue: AWS authentication fails
**Solution:**
- Run `aws configure` again
- Check IAM permissions
- Verify credentials haven't expired

### Issue: ECS tasks won't start
**Solution:**
- Check CloudWatch Logs for errors
- Verify ECR image exists and is accessible
- Check IAM role permissions
- Verify security group allows outbound traffic

### Issue: Target groups unhealthy
**Solution:**
- Verify health check endpoint exists (`/health`)
- Check security groups allow ALB to task communication
- Review application logs for errors
- Verify port mapping is correct

### Issue: Can't pull from ECR
**Solution:**
- Re-authenticate: `aws ecr get-login-password ... | docker login ...`
- Verify IAM permissions for ECR
- Check image tag exists

### Issue: Services can't communicate
**Solution:**
- Verify service discovery namespace
- Check security groups allow inter-service traffic
- Verify DNS resolution: `nslookup <service>.<namespace>`
- Check service endpoints in outputs

---

## 📞 Support Contacts

- **Terraform Issues**: [Your Team/Contact]
- **AWS Issues**: AWS Support or [Your AWS Admin]
- **Application Issues**: [Development Team]
- **Emergency**: [On-Call Contact]

---

## ✅ Final Verification

After deployment, you should have:
- [ ] All services showing "ACTIVE" status
- [ ] All target groups showing "healthy" targets
- [ ] ALB responding to requests
- [ ] CloudWatch Logs receiving data
- [ ] Service Discovery resolving names
- [ ] SQS queues created and accessible
- [ ] ECR repositories containing images
- [ ] Documentation updated
- [ ] Team notified of deployment

---

**Remember**: 
- ✅ Test in LocalStack first
- ✅ Always review `terraform plan` before applying
- ✅ Keep sensitive data out of version control
- ✅ Document everything
- ✅ Monitor after deployment

Good luck with your deployment! 🚀
