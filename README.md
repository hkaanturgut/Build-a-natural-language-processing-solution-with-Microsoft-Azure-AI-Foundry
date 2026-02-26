# Azure AI Natural Language Processing Solution

A comprehensive end-to-end Named Entity Recognition (NER) solution that leverages Azure AI Services to extract and classify entities from invoice documents. This project demonstrates how to build, train, and deploy custom NLP models using Azure's latest AI technologies with full CI/CD automation via GitHub Actions.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Step-by-Step Setup Guide](#step-by-step-setup-guide)
- [Usage Guide](#usage-guide)
- [Network Security](#network-security)
- [Contributing](#contributing)
- [Support & Documentation](#support--documentation)
- [License](#license)

---

## Overview

This project provides an end-to-end solution for building and deploying **custom Named Entity Recognition (NER)** models on Azure. The solution includes:

- **Fine-tuned NER Model**: A custom-trained model for extracting invoice-specific entities
- **Standard NER Model**: Azure's built-in Language Service for general entity extraction
- **Model Comparison Tool**: Side-by-side analysis of both approaches
- **Infrastructure as Code**: Full Terraform automation for Azure resource deployment with public access configuration
- **CI/CD Pipeline**: GitHub Actions workflow with automated Terraform plan and apply with manual approval gates
- **Centralized Configuration**: Environment-based configuration management with direct Key Vault integration
- **Automated Workflows**: Shell scripts and Makefile for easy execution

### Use Cases

- Extract structured data from invoices and receipts
- Identify products, prices, vendors, and dates
- Automate invoice processing pipelines via GitHub Actions
- Compare model performance across different NER approaches
- Scale NER models to production environments with Infrastructure as Code

---

## Prerequisites

### Azure Requirements

✅ **Active Azure Subscription** with:
- Sufficient quota for Language Service, AI Services, Storage, and Key Vault
- Permissions to create resource groups and resources
- Azure CLI authentication configured (`az login`)
- Storage account with container if you prefer to storage your Terraform state file in remote.

### Create Managed Identity or Service Principal

For GitHub Actions CI/CD pipeline, you need to create a **Managed Identity** or **Service Principal** with the following RBAC roles on the subscription:

https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-static-site-github-actions?tabs=openid#generate-deployment-credentials

<img width="1054" height="1068" alt="Screenshot 2025-12-21 at 4 23 45 PM" src="https://github.com/user-attachments/assets/e0f1c973-8268-4ad1-8690-98e3348c823d" />


#### Required RBAC Roles

| Role | Purpose |
|------|---------|
| **Contributor** | Create and manage Azure resources (Storage, Key Vault, AI Services) |
| **User Access Administrator** | Assign RBAC roles to created resources |
| **Key Vault Secrets Officer** | Create and manage secrets in Key Vault |


## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud Platform                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │          Azure Resource Group                        │  │
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
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────────────┐  ┌─────────────┐  ┌──────────────┐
    │   GitHub   │  │   Python    │  │   Terraform  │
    │   Actions  │  │   Scripts   │  │     CLI      │
    │ (CI/CD)    │  │ (NER Models)│  │ (IaC)        │
    └────────────┘  └─────────────┘  └──────────────┘
```

---

## Project Structure

This project is organized into three main directories:

### 📁 Directory Overview

```
Build-a-natural-language-processing-solution-with-Azure-AI-Foundry/
│
├── data/                              # 📊 Data Files
│   ├── invoices/                      # Training/validation invoice data (15 files)
│   └── test_invoices/                 # Test invoice samples (10 files)
│
├── infra/                             # 🏗️ Infrastructure as Code (Terraform)
│   ├── terraform/                     # Main Terraform module
│   │   ├── main.tf                    # Core Azure resources definition
│   │   ├── networking.tf              # Virtual network and security groups
│   │   ├── providers.tf               # Terraform & Azure provider config
│   │   ├── variables.tf               # Input variable definitions
│   │   ├── outputs.tf                 # Output values
│   │   ├── rbac.tf                    # Role-based access control
│   │   └── terraform.tfvars.example   # Example configuration template
│   │
│   ├── prod/                          # 🏭 Production environment
│   │   ├── main.tf                    # Production module reference
│   │   ├── providers.tf               # Production providers
│   │   ├── prod_terraform.tfvars      # Production variables
│   │   └── variables.tf               # Production variable definitions
│   │
│   └── az-cli/                        # 🔧 Azure CLI Scripts
│       ├── create-spn-federated-creds.bash  # Create SPN with OIDC federated credentials
│       └── assign-rbac-roles-spn.bash       # Assign required RBAC roles to SPN
│
├── python/                            # 🐍 Python Application Code
│   ├── config.py                      # Centralized configuration manager
│   ├── fine_tuned_ner.py              # Fine-tuned NER model script
│   ├── custom_ner.py                  # Standard Azure NER script
│   ├── model_comparison.py            # Model comparison tool
│   ├── requirements.txt               # Python package dependencies
│   ├── .env.example                   # Example environment template
│   └── __pycache__/                   # Python cache (auto-generated)
│
├── .github/                           # 🔄 GitHub Actions CI/CD
│   └── workflows/
│       └── terraform-deploy.yml       # Automated Terraform plan & apply workflow
│
├── README.md                          # 📖 This file - Main documentation
├── LICENSE                            # 📜 MIT License
├── .gitignore                         # Git ignore rules
```

### 📊 Data Directory (`data/`)

**Purpose**: Contains sample invoice documents for model training, validation, and testing.

- `invoices/` - 15 training/validation invoice samples
- `test_invoices/` - 10 test invoice samples for model evaluation

### 🏗️ Infrastructure Directory (`infra/`)

The infrastructure is organized into three deployment environments:

#### `terraform/` - Base Module
- **Purpose**: Reusable Terraform module for all environments
- **Contains**: All Azure resource definitions, variables, outputs, and RBAC configuration
- **Used by**: prod/ and qat/ environments as a module source

#### `prod/` - Production Environment
- **Purpose**: Production-grade deployment configuration
- **Configuration**: prod_terraform.tfvars
- **Resource naming**: `prod` environment suffix

#### `az-cli/` - Azure CLI Setup Scripts

**Purpose**: Shell scripts to create and configure the Service Principal (SPN) required for GitHub Actions CI/CD with OIDC authentication.

##### 1. Create SPN with Federated Credentials

```bash
chmod +x infra/az-cli/create-spn-federated-creds.bash
bash infra/az-cli/create-spn-federated-creds.bash
```

This script:
- Creates an Azure AD **App Registration** and **Service Principal**
- Configures **federated identity credentials** for GitHub Actions OIDC
- Uses entity type `environment` scoped to the `dev` environment
- Outputs the `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` values needed as GitHub secrets

##### 2. Assign RBAC Roles to the SPN

```bash
chmod +x infra/az-cli/assign-rbac-roles-spn.bash
bash infra/az-cli/assign-rbac-roles-spn.bash
```

This script assigns the following roles at the subscription scope:

| Role | Purpose |
|------|---------|
| **Contributor** | Create and manage Azure resources (Storage, Key Vault, AI Services) |
| **User Access Administrator** | Assign RBAC roles to created resources |
| **Key Vault Secrets Officer** | Create and manage secrets in Key Vault |

> **Note**: Run `create-spn-federated-creds.bash` first, then `assign-rbac-roles-spn.bash`. Update the `SPN_CLIENT_ID` variable in the RBAC script with the Client ID output from the first script.

### 🐍 Python Directory (`python/`)

**Purpose**: Python scripts for NER model execution and data processing.

- `config.py` - Centralized configuration manager that retrieves values from Terraform outputs and Key Vault
- `fine_tuned_ner.py` - Executes the fine-tuned NER model
- `custom_ner.py` - Executes the standard Azure Language Service NER
- `model_comparison.py` - Compares outputs of both models
- `requirements.txt` - Python dependencies (azure-identity, azure-storage-blob, etc.)

### 🔄 GitHub Actions CI/CD (`.github/workflows/`)

**Purpose**: Automated infrastructure deployment and testing.

- `terraform-deploy.yml` - Workflow that:
  - Runs `terraform plan` on pull requests
  - Requires manual approval before `terraform apply`
  - Automatically applies approved changes to Azure

---

## Step-by-Step Setup Guide

### Step 1: Clone Repository & Install Tools

```bash
# Clone the repository
git clone https://github.com/hkaanturgut/Build-a-natural-language-processing-solution-with-Azure-AI-Foundry.git
cd Build-a-natural-language-processing-solution-with-Azure-AI-Foundry

# Verify directory structure
ls -la
# Should show: data/ infra/ python/ .github/ Makefile README.md etc.
```

### Step 2: Verify Prerequisites

```bash
# Check Python installation
python3 --version     # Should be 3.9+

# Check Terraform installation
terraform --version   # Should be 1.6+

# Check Azure CLI installation
az --version          # Should be latest

# Verify Azure authentication
az account show       # Should display your subscription

# Verify service principal has required RBAC roles
az role assignment list --assignee <service-principal-id>
# Should include: Contributor, User Access Administrator, Key Vault Secrets Officer
```

### Step 3: Deploy Infrastructure (GitHub Actions)

The infrastructure deployment is automated via GitHub Actions CI/CD pipeline. No local Terraform commands needed!

**1. Ensure Service Principal is Configured in GitHub Secrets:**

Navigate to your repository or environment settings:
- **Settings** → **Secrets and variables** → **Actions**
- Verify these secrets exist: 
<img width="1896" height="868" alt="Screenshot 2025-12-13 at 6 47 22 PM" src="https://github.com/user-attachments/assets/9c43f0aa-0a34-4143-bed3-8351aed6849d" />


**2. Trigger the Deployment:**

```bash
# Push to main branch (or open a Pull Request)
git push origin main

# OR manually trigger from GitHub Actions
# Go to: Actions → Terraform Deploy → Run workflow → Select branch → Run workflow

<img width="1889" height="606" alt="Screenshot 2025-12-13 at 6 55 14 PM" src="https://github.com/user-attachments/assets/ef1f675b-4e9e-4f1c-b12d-407a8c6427f8" />

```

**Resources Created**:
- ✅ Resource Group (rg-nlp-{region}-{env}-{index})
- ✅ Storage Account with containers (invoices, reports, training)
- ✅ Language Service (Fine-tuned NER capability)
- ✅ AI Services (Multiple models: GPT-4, etc.)
- ✅ Key Vault (Secrets management for API keys)
- ✅ AI Foundry Hub & Project (Model management)
- ✅ Network infrastructure (Public access enabled)

  <img width="1336" height="650" alt="Screenshot 2025-12-13 at 6 55 59 PM" src="https://github.com/user-attachments/assets/63e16c08-ef8c-4b8f-880f-bfab49f64c5d" />


**NOTE**: 
Feel free to update the code and workflow based on your own networking structure. Resources are open to public for demo purposes

### Step 4: Connect The Necessary Resources to Microsoft Foundry

***Connect The Azure AI Language***
Go to Management Center in the Foundry project > New Connection > Azure AI Language > Select your resource and connect it

<img width="1891" height="834" alt="Screenshot 2025-12-13 at 6 59 35 PM" src="https://github.com/user-attachments/assets/50005a29-3d24-4708-a4ad-0b6e028b8061" />

***Connect the Invoices Storage Account Container***

From the same management center, add the storage account using SAS token from the Key Vault.

<img width="1764" height="726" alt="Screenshot 2025-12-13 at 8 22 39 PM" src="https://github.com/user-attachments/assets/d6be6911-6ae8-478b-be0c-f8ecac963323" />

<img width="1892" height="731" alt="Screenshot 2025-12-13 at 8 25 31 PM" src="https://github.com/user-attachments/assets/545e7a05-d8fa-4886-bfa9-8b0023efc4c6" />

### Step 5: Create AI Service Fine-Tuning

In order to create a Custom NER, go to to the AI project > Fine-tuning > click on + > Scroll to the bottom and select the Custom Named Entity Recognicition > Select the connected AI language resource and create

<img width="1906" height="888" alt="Screenshot 2025-12-13 at 9 23 17 PM" src="https://github.com/user-attachments/assets/384e2488-49c2-4715-8908-6fca30705a4e" />


### Step 6: Label Data

In order to fine-tune your model with some entities, we need to label the data. Add labels like "InvoiceNumber" and "ProductName" then label the data.

Make sure to at least label 10 documents as it's the minimum requirement and it's recommended to have at least 200 labeled entities.

Make sure to Save from the top before proceeding furhter.

<img width="1882" height="848" alt="Screenshot 2025-12-13 at 8 52 16 PM" src="https://github.com/user-attachments/assets/f7092f6e-1c7b-43fc-9b7c-4c4890660b08" />

### Step 7: Train The Model

After labeling the data, it's time to train our model based on those labels.

<img width="1883" height="845" alt="Screenshot 2025-12-13 at 8 52 54 PM" src="https://github.com/user-attachments/assets/87c61688-57b5-405b-9143-1791408aaa50" />

### Step 8: Deploy the Model

Upon training and evaluation the model, it's time to deploy it!

<img width="1892" height="855" alt="Screenshot 2025-12-13 at 8 54 04 PM" src="https://github.com/user-attachments/assets/8cb7782a-1978-4ca5-b1e9-b569c934a99e" />

Once the model is deployed, you can get the prediction URL along with the subscription key (ai language primary key) by clicking on the model name.

<img width="1903" height="863" alt="Screenshot 2025-12-13 at 8 54 38 PM" src="https://github.com/user-attachments/assets/5e43f115-8c7c-4155-803d-bb668c262593" />

### Step 4: Validate Configuration

```bash
# Navigate to python directory
cd python

# Test configuration loading
python3 -c "from config import Config; Config.validate(strict=True); Config.print_status()"

# Expected output:
# ============================================================
# Configuration Status
# ============================================================
# ✅ LANGUAGE_SERVICE_ENDPOINT: https://lang-qa-eus2-001...
# ✅ AI_FOUNDRY_PROJECT_NAME: v1
# ✅ AI_FOUNDRY_DEPLOYMENT_NAME: v2
# ============================================================
```

### Step 5: Run NER Models

```bash
# Run fine-tuned model on test data
python3 fine_tuned_ner.py

# Run standard NER model on test data
python3 custom_ner.py

# Compare both model outputs
python3 model_comparison.py

# Check generated reports
ls -la reports/
```

---
## Usage Guide

### Running the Fine-Tuned NER Model

The fine-tuned model uses your custom-trained Language Service model for entity extraction:

```bash
# Navigate to python directory
cd python

# Run the fine-tuned model
python3 fine_tuned_ner.py
```

**Output:**
- Console: Extracted entities with confidence scores
- Temporary file: `/tmp/fine_tuned_ner_results_<timestamp>.csv`
- Azure Storage: `reports/fine_tuned_ner_results_<timestamp>.csv` (if storage connection available)

**Sample Output:**
```
Processing test_invoice_001.txt
Entities found:
  - ProductName: "Premium Widget" (confidence: 0.98)
  - Date: "2024-01-15" (confidence: 0.95)
  - Amount: "$1,234.56" (confidence: 0.99)

```

<img width="736" height="1049" alt="Screenshot 2025-12-21 at 3 21 26 PM" src="https://github.com/user-attachments/assets/853d7ca8-e9b3-491f-9de6-50ad0c5d40bf" />

### Running the Standard NER Model

The standard model uses Azure Language Service's built-in NER capabilities:

```bash
# Run the standard NER model
python3 custom_ner.py
```

**Extracted Entity Types:**
- Person, Organization, Location
- DateTime, Quantity, Skill
- Product, Event, Facility
- GPELocation (Geopolitical entities)

### Running Model Comparison

Compare results from both models side-by-side:

```bash
# Run model comparison
python3 model_comparison.py
```

**Comparison Output:**
- Side-by-side entity extraction results
- Performance metrics (total entities, average confidence)
- Extraction coverage comparison
- CSV report: `model_comparison_results_<timestamp>.csv`

<img width="867" height="325" alt="Screenshot 2025-12-21 at 3 50 08 PM" src="https://github.com/user-attachments/assets/e10b76f3-93bc-4224-a9c7-f9854c19b504" />


### Batch Processing

Process all invoices in a directory:

```bash
# Fine-tuned model on all invoices
python3 fine_tuned_ner.py --input-dir ../data/invoices --output-dir reports

# Standard model with detailed output
python3 custom_ner.py --input-dir ../data/invoices --verbose
```

---

## Network Security

### Current Architecture: Public Access

This project is configured with **public access enabled** for simplified development and deployment.

#### Key Components

- **Virtual Network (VNet)**: `10.0.0.0/16` with 4 subnets for resource organization
- **Public Access**: All Azure services (Key Vault, Storage, Language Service) are publicly accessible
- **Authentication**: Azure identity-based (Service Principal or Managed Identity)
- **Encryption**: All communication uses HTTPS/TLS 1.2+
- **Network Security Groups**: NSG rules control inbound/outbound traffic

#### Public Access Configuration

All public network access is controlled via Terraform:

```hcl
# Enable public access for Key Vault
disable_public_network_access = false

# Enable public access for Storage Account
public_network_access_enabled = true

# Enable public access for Language Service
public_network_access_enabled = true
```

#### Security Best Practices (Even with Public Access)

✅ **Authentication**: Service Principal or Managed Identity required  
✅ **Encryption**: TLS 1.2+ for all communications  
✅ **Authorization**: RBAC role assignments (Contributor, Key Vault Officer)  
✅ **Secrets**: API keys stored in Azure Key Vault, never in code  
✅ **Access Logging**: Audit logs enabled for all resources  

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
