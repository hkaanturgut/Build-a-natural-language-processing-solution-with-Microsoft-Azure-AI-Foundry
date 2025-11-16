# Galaxy Gadgets NLP Infrastructure

This Terraform configuration creates the Azure infrastructure needed for the Galaxy Gadgets Natural Language Processing solution.

## 🚀 What Gets Created

In a single `terraform apply`, you'll get:

✅ **Resource group**: `rg-galaxy-gadgets-<env>`

✅ **Storage account** for datasets with containers for:
- `invoices` - Invoice documents for processing
- `logs` - Application and processing logs  
- `models` - Custom ML models and artifacts

✅ **Azure AI Foundry workspace** for:
- **AI agents** - Build conversational AI agents and assistants
- **PII detection** - Identify and redact personal information using AI models
- **Custom NER** - Custom Named Entity Recognition for invoice processing
- **CLU** - Conversational Language Understanding for Galaxy Order Assistant
- **Application Insights** - Monitoring and telemetry for AI applications

✅ **Key Vault** with secrets containing:
- AI Foundry workspace endpoint
- AI Foundry workspace ID
- Storage account connection string

✅ **Useful outputs** - All endpoints, names, and connection info

## 📋 Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** installed (v1.0+)
3. **Appropriate Azure permissions** to create resources

## 🛠️ Quick Start

### Option 1: Automated Setup (Recommended)

1. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Azure subscription ID
   ```

2. **Run setup script**
   ```bash
   ./setup.sh
   ```

3. **Deploy infrastructure**
   ```bash
   cd infra
   terraform init
   terraform plan
   terraform apply
   ```

### Option 2: Manual Setup

1. **Set up configuration files**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   
   cd infra
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize and deploy**
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```

## ⚙️ Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `subscription_id` | Azure subscription ID | None | **Yes** |
| `environment` | Environment name (dev/staging/prod) | `"dev"` | No |
| `location` | Azure region | `"East US"` | No |
| `storage_account_name` | Storage account name (globally unique) | `"stgalaxygadgets001"` | No |
| `ai_foundry_workspace_name` | AI Foundry workspace name | `"aif-galaxy-gadgets"` | No |
| `application_insights_name` | Application Insights name | `"ai-galaxy-gadgets"` | No |
| `key_vault_name` | Key Vault name (globally unique) | `"kv-galaxy-gadgets-001"` | No |
| `tags` | Resource tags | See variables.tf | No |

## 📊 Key Outputs

After deployment, you'll get these useful outputs:

```hcl
# Resource information
resource_group_name           = "rg-galaxy-gadgets-dev"
storage_account_name         = "stgalaxygadgets001"
ai_foundry_workspace_url     = "https://aif-galaxy-gadgets-dev.workspace.cognitiveservices.azure.com/"
key_vault_name              = "kv-galaxy-gadgets-dev"

# Storage containers
storage_containers = {
  invoices = "invoices"
  logs     = "logs" 
  models   = "models"
}

# Secret names in Key Vault
secret_names = {
  ai_foundry_endpoint       = "ai-foundry-endpoint"
  ai_foundry_workspace_id   = "ai-foundry-workspace-id"
  storage_connection_string = "storage-connection-string"
}
```

## 🔐 Security Features

- **Managed Identity** enabled for AI Foundry workspace
- **Key Vault** stores all sensitive credentials and connection strings
- **Storage account** with versioning and soft delete
- **TLS 1.2** minimum for storage
- **Private containers** with no public access
- **RBAC** configured for service-to-service access
- **Application Insights** for monitoring and telemetry

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

## 📁 File Structure

```
/
├── .env.example               # Example environment variables
├── setup.sh                   # Automated setup script
└── infra/
    ├── main.tf                # Main infrastructure definition
    ├── variables.tf           # Input variables
    ├── outputs.tf             # Output values
    ├── terraform.tfvars.example # Example configuration
    └── README.md              # This file
```

## 🔒 Security Notes

- **`.env`** and **`terraform.tfvars`** files are ignored by git (contain sensitive data)
- **Subscription ID** is marked as sensitive in Terraform variables
- **State files** and **plan files** are automatically ignored
- Use **`.env.example`** and **`terraform.tfvars.example`** as templates

## 🔧 Customization

### Different Environment

```bash
# For staging
terraform apply -var="environment=staging"

# For production  
terraform apply -var="environment=prod"
```

### Different Region

```bash
terraform apply -var="location=West US 2"
```

### Custom Workspace Name

```bash
terraform apply -var="ai_foundry_workspace_name=my-custom-workspace"
```

## 🚨 Important Notes

1. **Storage account names** must be globally unique (3-24 chars, lowercase alphanumeric)
2. **Key Vault names** must be globally unique (3-24 chars, alphanumeric and hyphens)
3. **AI Foundry workspace** provides comprehensive AI capabilities including model deployment and agents
4. **Application Insights** provides monitoring for AI applications and model performance
5. **Soft delete** is enabled with 7-day retention for security

## 📞 Support

For issues or questions:
1. Check Azure portal for resource status
2. Review Terraform state: `terraform show`
3. Validate configuration: `terraform validate`
4. Check outputs: `terraform output`