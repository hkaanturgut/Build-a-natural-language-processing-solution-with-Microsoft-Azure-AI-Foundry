# Azure AI Natural Language Processing Solution

A comprehensive **production-ready** Named Entity Recognition (NER) solution that leverages Azure AI Services to extract and classify entities from invoice documents. This project demonstrates how to build, train, and deploy custom NLP models using Azure's latest AI technologies.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technologies & Resources](#technologies--resources)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Step-by-Step Setup Guide](#step-by-step-setup-guide)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Key Features](#key-features)
- [Contributing](#contributing)

---

## Overview

This project provides an end-to-end solution for building and deploying **custom Named Entity Recognition (NER)** models on Azure. The solution includes:

- **Fine-tuned NER Model**: A custom-trained model for extracting invoice-specific entities
- **Standard NER Model**: Azure's built-in Language Service for general entity extraction
- **Model Comparison Tool**: Side-by-side analysis of both approaches
- **Infrastructure as Code**: Full Terraform automation for Azure resource deployment
- **Centralized Configuration**: Environment-based configuration management
- **Automated Workflows**: Shell scripts and Makefile for easy execution

### Use Cases

- Extract structured data from invoices and receipts
- Identify products, prices, vendors, and dates
- Automate invoice processing pipelines
- Compare model performance across different NER approaches
- Scale NER models to production environments

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud Platform                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │          Azure Resource Group (dev-v1)              │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │                                                     │  │
│  │  ┌──────────────────┐    ┌──────────────────────┐ │  │
│  │  │  Storage Account │    │  Key Vault (Secrets) │ │  │
│  │  │  - invoices      │    │  - API Keys          │ │  │
│  │  │  - reports       │    │  - Endpoints         │ │  │
│  │  │  - training data │    │  - Connections       │ │  │
│  │  └──────────────────┘    └──────────────────────┘ │  │
│  │           △                        △               │  │
│  │           │                        │               │  │
│  │  ┌────────┴────────────────────────┴────────────┐ │  │
│  │  │      Language Service (Fine-tuned NER)      │ │  │
│  │  │  - Custom Entity Recognition Model (v1)     │ │  │
│  │  │  - Project: v1 / Deployment: v2             │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │           △                                      │  │
│  │           │                                      │  │
│  │  ┌────────┴────────────────────────────────────┐ │  │
│  │  │        Azure AI Foundry Hub & Project       │ │  │
│  │  │  - AI Services Hub (multi-model management) │ │  │
│  │  │  - AI Foundry Project (v1)                  │ │  │
│  │  │  - Model Management & Deployment            │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                 │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
                         △
                         │
        ┌────────────────┴────────────────┐
        │                                 │
    ┌───────────────────┐      ┌──────────────────┐
    │   Python Scripts  │      │   Local Machine  │
    │  - fine_tuned_ner │      │  - Terraform CLI │
    │  - custom_ner     │      │  - Azure CLI     │
    │  - comparison     │      │  - Python 3      │
    └───────────────────┘      └──────────────────┘
```

---

## Technologies & Resources

### Azure Services

| Service | Purpose | Location | Tier |
|---------|---------|----------|------|
| **Azure Language Service** | Fine-tuned custom NER model | East US 2 | S1 (Standard) |
| **Azure AI Services** | Base AI services | East US 2 | S0 (Standard) |
| **Azure Storage Account** | Data storage (invoices, reports) | East US 2 | Standard LRS |
| **Azure Key Vault** | Secrets & credentials management | East US 2 | Standard |
| **Azure AI Foundry Hub** | AI model hub & project management | East US 2 | Standard |
| **Azure AI Foundry Project** | Custom model project workspace | East US 2 | Standard |

### Development Technologies

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Python** | 3.9+ | NER scripts & automation |
| **Terraform** | 1.0+ | Infrastructure as Code (IaC) |
| **Azure CLI** | Latest | Azure resource management |
| **Bash/Shell** | POSIX | Automation scripts |
| **Azure SDK for Python** | Latest | Azure service integration |

### Python Libraries

```
azure-identity          # Authentication with Azure
azure-keyvault-secrets  # Key Vault integration
azure-storage-blob      # Blob storage operations
azure-ai-textanalytics  # Azure Language Service NER
requests                # HTTP API calls
python-dotenv           # Environment variable management
```

### Project Dependencies

- **dotenv**: Configuration management
- **Requests**: REST API communication
- **Azure Python SDK**: Cloud resource interaction

---

## Prerequisites

### System Requirements

- **OS**: macOS, Linux, or Windows (WSL2)
- **Python**: 3.9 or higher
- **Terraform**: 1.0 or higher
- **Azure CLI**: Latest version
- **Git**: For version control

### Azure Requirements

✅ **Active Azure Subscription** with:
- Sufficient quota for Language Service, AI Services, Storage
- Permissions to create resource groups and resources
- Authentication configured (Azure CLI login)

### Installation

1. **Install Python 3.9+**
   ```bash
   # macOS
   brew install python@3.11

   # Linux (Ubuntu/Debian)
   sudo apt-get install python3.11

   # Verify installation
   python3 --version
   ```

2. **Install Terraform**
   ```bash
   # macOS
   brew install terraform

   # Linux
   sudo apt-get install terraform

   # Verify installation
   terraform --version
   ```

3. **Install Azure CLI**
   ```bash
   # macOS
   brew install azure-cli

   # Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Verify installation
   az --version
   ```

4. **Authenticate with Azure**
   ```bash
   az login
   az account set --subscription <YOUR_SUBSCRIPTION_ID>
   ```

5. **Clone this Repository**
   ```bash
   git clone https://github.com/hkaanturgut/Build-a-natural-language-processing-solution-with-Azure-AI-Foundry.git
   cd Build-a-natural-language-processing-solution-with-Azure-AI-Foundry
   ```

---

## Project Structure

```
.
├── README.md                          # This file - Project documentation
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── NAMING-CONVENTION.md               # Resource naming standards
├── AUTOMATION_IMPROVEMENTS.md         # Automation enhancements summary
├── AUTOMATION_AUDIT.md                # Detailed automation audit
├── QUICKSTART.md                      # Quick start guide
│
├── infra/                             # Infrastructure as Code (Terraform)
│   ├── main.tf                        # Main resource definitions
│   ├── providers.tf                   # Azure provider configuration
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output values
│   ├── rbac.tf                        # Role-based access control
│   ├── terraform.tfvars               # Terraform variables (values)
│   ├── terraform.tfvars.example       # Example tfvars template
│   ├── backend.hcl                    # Remote backend configuration
│   └── backend.hcl.example            # Example backend config
│
├── python/                            # Python application code
│   ├── __init__.py                    # Package initialization
│   ├── config.py                      # Centralized configuration
│   ├── fine_tuned_ner.py              # Fine-tuned NER model script
│   ├── custom_ner.py                  # Standard NER model script
│   ├── model_comparison.py            # Model comparison tool
│   ├── requirements.txt                # Python dependencies
│   ├── .env                           # Environment variables (generated)
│   └── .env.example                   # Example environment template
│
├── scripts/                           # Automation scripts
│   ├── preflight-check.sh             # Configuration validation
│   ├── run-python-script.sh           # Base Python script wrapper
│   ├── run-fine-tuned-ner.sh          # Fine-tuned NER runner
│   ├── run-custom-ner.sh              # Custom NER runner
│   ├── run-model-comparison.sh        # Model comparison runner
│   └── check-requirements.sh          # System requirements checker
│
├── data/                              # Data files
│   ├── invoices/                      # Invoice training/validation data
│   ├── test_invoices/                 # Test invoice samples (10 files)
│   └── reports/                       # Generated report outputs
│
├── deploy-all.sh                      # Master orchestration script
├── update-env.sh                      # Terraform output → .env exporter
├── Makefile                           # Command shortcuts
├── setup.sh                           # Initial setup script
└── QAT/                               # Quality Assurance Testing (project-specific)
```

---

## Quick Start

### Option 1: Fully Automated (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/hkaanturgut/Build-a-natural-language-processing-solution-with-Azure-AI-Foundry.git
cd Build-a-natural-language-processing-solution-with-Azure-AI-Foundry

# 2. Set your Azure Subscription ID
export AZURE_SUBSCRIPTION_ID="your-subscription-id"

# 3. Complete automated setup (Terraform + Python environment)
./deploy-all.sh

# 4. Run fine-tuned NER model
make run-fine-tuned

# 5. Compare both models
make run-comparison
```

### Option 2: Using Makefile Commands

```bash
# Check system requirements
make check-requirements

# Complete setup
make setup

# Run models
make run-fine-tuned     # Fine-tuned model
make run-custom         # Standard model
make run-comparison     # Compare both

# Clean up
make clean              # Clean generated files
make full-clean         # Clean + destroy infrastructure
```

### Option 3: Manual Step-by-Step

```bash
# See "Step-by-Step Setup Guide" section below
```

---

## Step-by-Step Setup Guide

### Step 1: Prepare Your Environment

```bash
# 1. Navigate to project directory
cd Build-a-natural-language-processing-solution-with-Azure-AI-Foundry

# 2. Set your Azure Subscription ID (required by Terraform)
export AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 3. Verify Azure CLI authentication
az account show
```

### Step 2: Deploy Infrastructure with Terraform

```bash
# 1. Navigate to infrastructure directory
cd infra

# 2. Initialize Terraform
terraform init

# 3. Plan the deployment (review resources)
terraform plan

# 4. Apply the configuration (creates Azure resources)
terraform apply
# When prompted, type: yes

# 5. Verify outputs
terraform output
```

**Resources Created:**
- ✅ Resource Group (rg-ai-eus2-dev-001)
- ✅ Storage Account (stnlpdeveus001) with containers
- ✅ Language Service (lang-qa-eus2-001)
- ✅ AI Services (ais-dev-eus2-001)
- ✅ Key Vault (kv-qa-eus2-ai-001)
- ✅ AI Foundry Hub & Project
- ✅ GPT model deployment

### Step 3: Export Terraform Outputs to Python Environment

```bash
# 1. Return to project root
cd ..

# 2. Export all Terraform outputs to python/.env
./update-env.sh
# Output: Updated python/.env with Terraform values

# 3. Verify the .env file
cat python/.env
```

### Step 4: Set Up Python Environment

```bash
# 1. Navigate to python directory
cd python

# 2. Create virtual environment
python3 -m venv ../../.venv

# 3. Activate virtual environment
source ../../.venv/bin/activate

# 4. Upgrade pip
pip install --upgrade pip

# 5. Install dependencies
pip install -r requirements.txt

# 6. Verify installation
python3 -c "import azure.identity; print('✅ Azure SDK installed')"
```

### Step 5: Validate Configuration

```bash
# 1. Run preflight checks
bash scripts/preflight-check.sh

# Expected output:
# ✅ .env file found
# ✅ Required variables present
# ✅ Test data directory found
# ✅ Virtual environment available
```

### Step 6: Run NER Models

```bash
# Option A: Run fine-tuned model
python3 python/fine_tuned_ner.py

# Option B: Run standard NER model
python3 python/custom_ner.py

# Option C: Compare both models
python3 python/model_comparison.py
```

---

## Usage

### 1. Fine-Tuned NER Model

Extracts entities using your custom-trained model (Project: `v1`, Deployment: `v2`).

```bash
# Run the script
python3 python/fine_tuned_ner.py

# Or using wrapper
bash scripts/run-fine-tuned-ner.sh

# Or using Makefile
make run-fine-tuned
```

**Output:**
- Console: Entity extraction details with confidence scores
- CSV Report: `/tmp/fine_tuned_ner_results_<timestamp>.csv`
- Azure Storage: `reports/fine_tuned_ner_results_<timestamp>.csv`

**Extracted Entity Types:**
- ProductName (custom entity for your domain)

### 2. Standard NER Model

Uses Azure's built-in Language Service NER capabilities.

```bash
# Run the script
python3 python/custom_ner.py

# Or using wrapper
bash scripts/run-custom-ner.sh

# Or using Makefile
make run-custom
```

**Extracted Entity Types:**
- DateTime, Organization, PersonType, Product, Quantity, Skill, etc.

### 3. Model Comparison Tool

Run both models on the same test data and compare results.

```bash
# Run comparison
python3 python/model_comparison.py

# Or using Makefile
make run-comparison
```

**Comparison Output:**
- Side-by-side entity extraction results
- Performance metrics (count, confidence, coverage)
- CSV comparison report
- HTML visualization (if configured)

---

## Configuration

### Environment Variables

The `python/.env` file contains all configuration:

```dotenv
# Key Vault (Secrets Management)
KEY_VAULT_URI=https://kv-qa-eus2-ai-001.vault.azure.net/

# Language Service (NER API)
LANGUAGE_SERVICE_ENDPOINT=https://lang-qa-eus2-001.cognitiveservices.azure.com/
LANGUAGE_SERVICE_API_VERSION=2024-11-15-preview

# AI Foundry (Project & Deployment)
AI_FOUNDRY_PROJECT_NAME=v1
AI_FOUNDRY_DEPLOYMENT_NAME=v2

# Storage Account (Data Management)
STORAGE_ACCOUNT_NAME=stnlpdeveus001
STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;...
```

### Terraform Variables

Edit `infra/terraform.tfvars` to customize:

```hcl
# Location & Environment
location    = "East US 2"      # Azure region
environment = "dev"           # Environment name (dev, qa, prod)

# Storage Configuration
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"
storage_account_kind             = "StorageV2"

# Key Vault Configuration
key_vault_sku_name = "standard"
enable_key_vault_rbac = true

# Language Service Configuration
language_service_sku = "S1"     # Standard tier
language_service_kind = "TextAnalytics"

# AI Services Configuration
ai_services_sku = "S0"          # Standard tier
ai_services_public_network_access = "Enabled"

# Blob Storage Configuration
enable_blob_versioning = true
enable_blob_change_feed = true
blob_soft_delete_retention_days = 7

# CORS Configuration
storage_cors_allowed_methods = ["GET", "POST", "PUT"]
storage_cors_allowed_origins = ["*"]
```

### Python Configuration (config.py)

The centralized `python/config.py` module handles all configuration:

```python
from config import Config

# Validate configuration on startup
Config.validate(strict=True)

# Access configuration
endpoint = Config.LANGUAGE_SERVICE_ENDPOINT
project = Config.AI_FOUNDRY_PROJECT_NAME
key = Config.get_language_service_key()  # From Key Vault

# Print status
Config.print_status()
```

---

## Troubleshooting

### Issue: Configuration Validation Fails

```
❌ Missing required configuration variables:
   - LANGUAGE_SERVICE_ENDPOINT
   - AI_FOUNDRY_PROJECT_NAME
```

**Solution:**
```bash
# 1. Ensure Terraform has been applied
cd infra && terraform apply

# 2. Export Terraform outputs to .env
../update-env.sh

# 3. Verify .env file
cat ../python/.env
```

### Issue: 401 Unauthorized (API Key Error)

```
ERROR] API request error: 401
[ERROR] Response body: {"error":{"code":"Unauthorized",...}}
```

**Solution:**
```bash
# 1. Verify Key Vault URI matches the endpoint
echo "Key Vault: $(grep KEY_VAULT_URI python/.env)"
echo "Endpoint: $(grep LANGUAGE_SERVICE_ENDPOINT python/.env)"

# 2. Verify the API key in Key Vault
az keyvault secret show --vault-name <kv-name> --name language-service-key

# 3. If keys don't match, update Key Vault
az keyvault secret set --vault-name <kv-name> \
  --name language-service-key \
  --value "<your-api-key>"
```

### Issue: Test Invoices Not Found

```
Error: Test invoices directory not found
```

**Solution:**
```bash
# Ensure test data exists
ls -la data/test_invoices/

# If missing, restore from git
git checkout data/test_invoices/
```

### Issue: Python Dependencies Missing

```
ModuleNotFoundError: No module named 'azure.identity'
```

**Solution:**
```bash
# 1. Activate virtual environment
source .venv/bin/activate

# 2. Install dependencies
pip install -r python/requirements.txt

# 3. Verify installation
pip list | grep azure
```

### Issue: Terraform State Issues

```
Error: Error acquiring the lock on <remote state>
```

**Solution:**
```bash
# 1. Unlock the state
terraform force-unlock <LOCK_ID>

# 2. Or use local state for testing
rm -f .terraform/terraform.tfstate.d/default

# 3. Re-initialize
terraform init
```

---

## Key Features

### 🎯 Custom NER Model
- Fine-tuned on your domain-specific data
- High accuracy for invoices and receipts
- Customizable entity types

### 🔄 Dual Model Support
- Compare fine-tuned vs. standard NER
- Evaluate model performance
- Choose best approach for your use case

### ☁️ Azure AI Integration
- Language Service for NER
- AI Foundry for model management
- Key Vault for secure credential storage
- Storage Account for data management

### 🏗️ Infrastructure as Code
- Complete Terraform automation
- Reproducible deployments
- Multi-environment support (dev, qa, prod)
- RBAC and security best practices

### 🔒 Enterprise Security
- Azure Key Vault integration
- Managed identities for services
- RBAC role assignments
- Private networking support

### 📊 Reporting & Export
- CSV export of results
- Azure Storage integration
- Comparison reports
- Performance metrics

### ⚙️ Automation & Convenience
- Makefile for common tasks
- Shell script wrappers
- Centralized configuration
- One-command setup

---

## Contributing

### Branch Strategy

- **main**: Production-ready code
- **dev-v1**: Active development branch
- **feature/***: Feature branches

### Development Workflow

1. Create feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make changes and commit
   ```bash
   git add .
   git commit -m "feat: description of changes"
   ```

3. Push and create Pull Request
   ```bash
   git push origin feature/your-feature-name
   ```

4. Request code review and merge

### Code Style

- Python: PEP 8 compliant
- Terraform: `terraform fmt` compliant
- Bash: ShellCheck compliant

---

## Support & Documentation

### Additional Resources

- [Azure Language Service Documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/language-service/)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Python SDK](https://github.com/Azure/azure-sdk-for-python)

### Detailed Guides

- [QUICKSTART.md](./QUICKSTART.md) - Quick start guide (3-5 minutes)
- [AUTOMATION_AUDIT.md](./AUTOMATION_AUDIT.md) - Automation analysis
- [AUTOMATION_IMPROVEMENTS.md](./AUTOMATION_IMPROVEMENTS.md) - Recent improvements
- [NAMING-CONVENTION.md](./NAMING-CONVENTION.md) - Resource naming standards

### Troubleshooting & FAQ

See the [Troubleshooting](#troubleshooting) section above or check the detailed guides.

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

## Contact & Issues

- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas
- **Pull Requests**: Contribute improvements

---

**Last Updated**: December 2024
**Status**: Production Ready ✅
**Version**: 1.0.0