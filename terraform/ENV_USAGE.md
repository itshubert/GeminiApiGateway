# How to Use .env File with Terraform

This guide shows you how to load sensitive values from your `.env` file instead of hardcoding them in `terraform.tfvars`.

## 🎯 Why Use .env Files?

✅ **Security**: Keep sensitive data out of `terraform.tfvars`  
✅ **Convenience**: Reuse the same `.env` file for docker-compose and Terraform  
✅ **Git-Safe**: `.env` is already in `.gitignore`  
✅ **Team-Friendly**: Each developer has their own `.env` file

## 🚀 Quick Start

### 1. Make sure your `.env` file exists

Your `.env` file should be in the project root:
```
GeminiApiGateway/
├── .env                    ← Your environment variables here
├── docker-compose.yml
└── terraform/
    └── environments/
        └── localstack/
            ├── load-env.ps1  ← Script to load .env
            └── terraform.tfvars
```

### 2. Load environment variables

**Option A: Use the load script (Recommended)**
```powershell
cd terraform\environments\localstack
.\load-env.ps1
terraform plan
```

**Option B: Load and apply in one command**
```powershell
cd terraform\environments\localstack
.\load-env.ps1; terraform apply
```

### 3. The variables are now available to Terraform!

The `load-env.ps1` script reads your `.env` file and sets environment variables with the `TF_VAR_` prefix that Terraform automatically recognizes.

## 📋 How It Works

### Your .env file:
```env
GeminiCatalogDbContext="Host=postgres;Port=5432;Database=geminicatalog;Username=postgres;Password=Blackbox57!"
GeminiCustomerDbContext="Host=postgres;Port=5432;Database=geminicustomer;Username=postgres;Password=Blackbox57!"
CERTIFICATE_PASSWORD=Soft8410993!
```

### The load-env.ps1 script converts them to:
```powershell
$env:TF_VAR_catalog_db_connection = "Host=postgres;Port=5432;..."
$env:TF_VAR_customer_db_connection = "Host=postgres;Port=5432;..."
$env:TF_VAR_certificate_password = "Soft8410993!"
```

### Terraform reads them automatically:
```hcl
variable "catalog_db_connection" {
  type = string
}
# Terraform automatically picks up TF_VAR_catalog_db_connection
```

## 🔄 Alternative Methods

### Method 1: Manual Environment Variables
```powershell
$env:TF_VAR_catalog_db_connection = "Host=postgres;..."
$env:TF_VAR_certificate_password = "YourPassword"
terraform plan
```

### Method 2: Command-line flags
```powershell
terraform plan `
  -var="catalog_db_connection=Host=postgres;..." `
  -var="certificate_password=YourPassword"
```

### Method 3: terraform.tfvars (Not Recommended for Secrets)
```hcl
# terraform.tfvars
catalog_db_connection = "Host=postgres;..."  # ⚠️ Don't commit this!
```

## 🛠️ Customizing the Script

The `load-env.ps1` script maps your `.env` keys to Terraform variable names:

```powershell
switch ($key) {
    "GeminiCatalogDbContext" {
        $env:TF_VAR_catalog_db_connection = $value
    }
    "CERTIFICATE_PASSWORD" {
        $env:TF_VAR_certificate_password = $value
    }
    # Add more mappings as needed
}
```

To add more variables:
1. Add them to your `.env` file
2. Add a mapping in the `switch` statement
3. Make sure the variable exists in `variables.tf`

## 🔐 Security Best Practices

### ✅ DO:
- Keep `.env` in `.gitignore` (already done)
- Use different `.env` files per environment (`.env.dev`, `.env.prod`)
- Use AWS Secrets Manager for production
- Share `.env.example` with your team (without real values)

### ❌ DON'T:
- Commit `.env` to Git
- Share `.env` files via chat/email
- Use the same passwords across environments
- Hardcode secrets in `terraform.tfvars` (especially if committing to Git)

## 📝 Example Workflow

### LocalStack Development:
```powershell
# 1. Make sure LocalStack is running
localstack start

# 2. Navigate to environment
cd terraform\environments\localstack

# 3. Load variables from .env
.\load-env.ps1

# 4. Initialize (first time only)
terraform init

# 5. Plan changes
terraform plan

# 6. Apply
terraform apply
```

### AWS Production:
```powershell
cd terraform\environments\aws

# Load from .env (or use Secrets Manager)
.\load-env.ps1

terraform plan
terraform apply
```

## 🐛 Troubleshooting

### "Error: No value for required variable"
**Problem**: Terraform can't find the variable value.

**Solution**: Make sure you ran `load-env.ps1` in the **same PowerShell session**:
```powershell
.\load-env.ps1
terraform plan  # Run in same session
```

Or check the variable was set:
```powershell
echo $env:TF_VAR_catalog_db_connection
```

### "Cannot find path '.env'"
**Problem**: The `.env` file path is wrong.

**Solution**: The script looks for `.env` at `../../../.env` (project root). Adjust the path in `load-env.ps1` if needed:
```powershell
$envFile = "../../../.env"  # Adjust this path
```

### Variables not persisting across sessions
**Problem**: Environment variables are session-specific.

**Solution**: Run `load-env.ps1` every time you open a new PowerShell session, or add to your profile:
```powershell
# In your PowerShell profile
function Load-TerraformEnv {
    & "D:\path\to\terraform\environments\localstack\load-env.ps1"
}
```

## 🎓 Advanced: Using .envrc with direnv

If you want automatic loading when you `cd` into the directory:

1. Install `direnv` for Windows
2. Create `.envrc` file:
   ```bash
   source .env
   export TF_VAR_catalog_db_connection=$GeminiCatalogDbContext
   export TF_VAR_customer_db_connection=$GeminiCustomerDbContext
   # ... etc
   ```
3. Run `direnv allow`

## 🔗 Related Files

- `.env` - Your environment variables (not in Git)
- `.env.example` - Template (safe to commit)
- `load-env.ps1` - Script to load .env into Terraform
- `terraform.tfvars` - Non-sensitive configuration
- `variables.tf` - Variable declarations

## 💡 Quick Reference

| Method | Security | Convenience | Best For |
|--------|----------|-------------|----------|
| load-env.ps1 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Local development |
| TF_VAR_ env vars | ⭐⭐⭐⭐ | ⭐⭐⭐ | CI/CD pipelines |
| terraform.tfvars | ⭐⭐ | ⭐⭐⭐⭐⭐ | Non-sensitive only |
| -var flags | ⭐⭐⭐ | ⭐⭐ | One-off overrides |
| Secrets Manager | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Production |

---

**Need more help?** Check `CONFIGURATION.md` for detailed configuration documentation.
