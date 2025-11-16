# Azure Resource Naming Convention

## Project: Build-a-natural-language-processing-solution-with-Azure-AI-Foundry

This document defines the naming conventions used for Azure resources in this NLP AI Foundry solution.

## Project Identifier
- **Project Abbreviation**: `nlp-ai-foundry`
- **Full Project Name**: NLP-AI-Foundry-Solution
- **Repository**: Build-a-natural-language-processing-solution-with-Azure-AI-Foundry

## Naming Pattern
```
{resource-prefix}-{project-id}-{environment}-{location-short}-{sequence}
```

**Components:**
- `resource-prefix`: Azure resource type abbreviation (e.g., rg, st, kv, ais, aif)
- `project-id`: `nlp` (Natural Language Processing)
- `environment`: `dev`, `staging`, `prod`
- `location-short`: Location abbreviation (e.g., `eus` for East US, `weu` for West Europe)
- `sequence`: 3-digit sequence number (001, 002, etc.)

## Resource Prefixes (Following Azure Best Practices)

| Resource Type | Prefix | Example |
|---------------|---------|---------|
| Resource Group | `rg-` | `rg-nlp-ai-foundry-dev` |
| Storage Account | `st` | `stnlpaifoundrydev001` |
| Key Vault | `kv-` | `kv-nlp-ai-foundry-dev-abc12345` |
| AI Services | `ais-` | `ais-nlp-ai-foundry-dev-abc12345` |
| AI Foundry Hub | `aif-` | `aif-nlp-ai-foundry-dev-abc12345` |
| AI Foundry Project | `aifp-` | `aifp-nlp-ai-foundry-dev-project` |

## Environment Identifiers
- `dev` - Development
- `staging` - Staging/Testing
- `prod` - Production

## Component Naming Examples

### Current Resource Names (Development Environment)
- **Resource Group**: `rg-nlp-ai-foundry-dev`
- **Storage Account**: `stnlpaifoundrydev001`
- **AI Services**: `ais-nlp-ai-foundry-dev-{random}`
- **AI Foundry Hub**: `aif-nlp-ai-foundry-dev-{random}`
- **AI Foundry Project**: `aifp-nlp-ai-foundry-dev-project`
- **Key Vault**: `kv-nlp-ai-foundry-dev-{random}`

### Storage Container Names
- `invoices` - For document processing training data
- `logs` - For application and processing logs
- `models` - For trained NLP models and artifacts

### Key Vault Secret Names
- `ai-foundry-id` - AI Foundry Hub resource ID
- `ai-foundry-project-id` - AI Foundry Project resource ID
- `ai-services-endpoint` - AI Services endpoint URL
- `storage-connection-string` - Storage account connection string

## Tagging Strategy

All resources use consistent tags:

```hcl
tags = {
  Environment = "Development|Staging|Production"
  Project     = "NLP-AI-Foundry-Solution"
  Owner       = "AI Team"
  Purpose     = "Natural-Language-Processing"
  Repository  = "Build-a-natural-language-processing-solution-with-Azure-AI-Foundry"
  CreatedBy   = "Terraform"
}
```

## Naming Rules & Constraints

### Storage Account Names
- **Length**: 3-24 characters
- **Characters**: Lowercase letters and numbers only
- **Global Uniqueness**: Required
- **Example**: `stnlpaifoundrydev001`

### Key Vault Names
- **Length**: 3-24 characters
- **Characters**: Alphanumeric and hyphens
- **Global Uniqueness**: Required
- **Pattern**: `kv-nlp-ai-foundry-{env}-{random}`

### AI Services Names
- **Characters**: Alphanumeric and hyphens
- **Global Uniqueness**: Required (for custom subdomain)
- **Pattern**: `ais-nlp-ai-foundry-{env}-{random}`

## Environment-Specific Examples

### Development Environment
```
Resource Group:     rg-nlp-ai-foundry-dev
Storage Account:    stnlpdeveus001
AI Services:        ais-nlp-dev-eus-001
AI Foundry Hub:     aif-nlp-dev-eus-001
AI Foundry Project: aifp-nlp-dev-eus-001
Key Vault:          kv-nlp-dev-eus-001
```

### Production Environment (Example)
```
Resource Group:     rg-nlp-ai-foundry-prod
Storage Account:    stnlpprodeus001
AI Services:        ais-nlp-prod-eus-001
AI Foundry Hub:     aif-nlp-prod-eus-001
AI Foundry Project: aifp-nlp-prod-eus-001
Key Vault:          kv-nlp-prod-eus-001
```

## Security and Access Control

### Key Vault RBAC (Modern Practice)
This infrastructure uses RBAC (Role-Based Access Control) instead of legacy access policies:

- **Key Vault Administrator**: Assigned to the current user for full management
- **Key Vault Secrets User**: Assigned to AI Foundry managed identities for reading secrets
- **Enable RBAC Authorization**: `enable_rbac_authorization = true`

### Managed Identities
All Azure services use system-assigned managed identities:
- AI Foundry Hub: System-assigned managed identity
- AI Foundry Project: System-assigned managed identity
- No stored credentials or connection strings in code

## Benefits of This Convention

1. **Clarity**: Resource purpose is immediately clear from the name
2. **Consistency**: All resources follow the same pattern
3. **Environment Separation**: Easy to identify development vs production resources
4. **Location Awareness**: Location is embedded in the name for multi-region deployments
5. **Sequence Management**: 3-digit sequence allows for multiple instances
6. **Azure Compliance**: Follows Microsoft's recommended naming conventions
7. **Security First**: Uses RBAC and managed identities instead of legacy access policies
8. **Scalability**: Pattern works for additional environments, locations, and components
9. **Automation Friendly**: Consistent pattern enables better DevOps automation
10. **No Random Strings**: Predictable, professional naming without random suffixes

## Usage in Terraform

The naming convention is implemented using Terraform variables and string interpolation:

```hcl
# Resource Group
name = "rg-nlp-ai-foundry-${var.environment}"

# AI Services with random suffix for uniqueness
name = "ais-nlp-ai-foundry-${var.environment}-${random_string.unique.result}"

# Storage Account (alphanumeric only)
name = var.storage_account_name # stnlpaifoundrydev001
```

This ensures consistent naming across all infrastructure deployments while maintaining the flexibility to deploy to multiple environments.