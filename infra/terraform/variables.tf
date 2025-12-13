variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "resource_index" {
  description = "Index to append to resource names for uniqueness"
  type        = string
  default     = "01"
  
}

variable "storage_account_name" {
  description = "Name of the storage account for datasets (must be globally unique)"
  type        = string
  default     = "staideveus2001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "ai_foundry_workspace_name" {
  description = "Name of the Azure AI Foundry workspace"
  type        = string
  default     = "aif-nlp-ai-foundry"
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique)"
  type        = string
  default     = "kv-nlp"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be between 3 and 24 characters long and contain only alphanumeric characters and hyphens."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "NLP-AI-Foundry-Solution"
    Owner       = "AI Team"
    Purpose     = "Natural-Language-Processing"
    Repository  = "Build-a-natural-language-processing-solution-with-Azure-AI-Foundry"
  }
}

# Storage Account Configuration
variable "storage_account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be either Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "storage_account_kind" {
  description = "Storage account kind (StorageV2 or BlobStorage)"
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["StorageV2", "BlobStorage"], var.storage_account_kind)
    error_message = "Storage account kind must be either StorageV2 or BlobStorage."
  }
}

variable "min_tls_version" {
  description = "Minimum TLS version for storage account"
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Minimum TLS version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted blobs"
  type        = number
  default     = 7

  validation {
    condition     = var.blob_soft_delete_retention_days >= 1 && var.blob_soft_delete_retention_days <= 365
    error_message = "Blob soft delete retention days must be between 1 and 365."
  }
}

variable "container_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted containers"
  type        = number
  default     = 7

  validation {
    condition     = var.container_soft_delete_retention_days >= 1 && var.container_soft_delete_retention_days <= 365
    error_message = "Container soft delete retention days must be between 1 and 365."
  }
}

# AI Services Configuration
variable "ai_services_sku" {
  description = "SKU for Azure AI Services (S0, S1, S2, etc.)"
  type        = string
  default     = "S0"
}

# Language Service Configuration
variable "language_service_sku" {
  description = "SKU for Language Service (F0, S or S1)"
  type        = string
  default     = "S"

  validation {
    condition     = contains(["F0", "S", "S1"], var.language_service_sku)
    error_message = "Language service SKU must be one of: F0, S, S1."
  }
}

# AI Foundry Configuration
variable "ai_foundry_public_network_access" {
  description = "Enable public network access for AI Foundry"
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.ai_foundry_public_network_access)
    error_message = "Public network access must be either Enabled or Disabled."
  }
}

# Key Vault Configuration
variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection on Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault items"
  type        = number
  default     = 90

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Key Vault soft delete retention days must be between 7 and 90."
  }
}

# Model Deployment Configuration
variable "gpt_model_deployment_name" {
  description = "Name of the GPT model deployment"
  type        = string
  default     = "gpt-5-chat"
}

variable "gpt_model_format" {
  description = "Format of the GPT model"
  type        = string
  default     = "OpenAI"
}

variable "gpt_model_name" {
  description = "Name of the GPT model"
  type        = string
  default     = "gpt-5-chat"
}

variable "gpt_model_version" {
  description = "Version of the GPT model"
  type        = string
  default     = "2025-10-03"
}

variable "gpt_deployment_sku_name" {
  description = "SKU name for GPT deployment"
  type        = string
  default     = "GlobalStandard"
}

variable "gpt_deployment_sku_capacity" {
  description = "Capacity for GPT deployment"
  type        = number
  default     = 1

  validation {
    condition     = var.gpt_deployment_sku_capacity >= 1
    error_message = "GPT deployment capacity must be at least 1."
  }
}

variable "ai_services_api_version" {
  description = "API version for Azure AI Services deployments"
  type        = string
  default     = "2023-05-01"
}

# Storage Account Features Configuration
variable "enable_storage_https_only" {
  description = "Enable HTTPS only for storage account"
  type        = bool
  default     = true
}

variable "enable_storage_public_access" {
  description = "Enable public network access for storage account"
  type        = bool
  default     = true
}

variable "allow_storage_nested_public_access" {
  description = "Allow nested items to be public in storage"
  type        = bool
  default     = false
}

variable "enable_blob_versioning" {
  description = "Enable blob versioning for storage account"
  type        = bool
  default     = true
}

variable "enable_blob_change_feed" {
  description = "Enable blob change feed for storage account"
  type        = bool
  default     = true
}

# CORS Configuration
variable "storage_cors_allowed_headers" {
  description = "CORS allowed headers for storage account"
  type        = list(string)
  default     = ["*"]
}

variable "storage_cors_allowed_methods" {
  description = "CORS allowed methods for storage account"
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT", "PATCH"]
}

variable "storage_cors_allowed_origins" {
  description = "CORS allowed origins for storage account"
  type        = list(string)
  default     = ["*"]
}

variable "storage_cors_exposed_headers" {
  description = "CORS exposed headers for storage account"
  type        = list(string)
  default     = ["*"]
}

variable "storage_cors_max_age_seconds" {
  description = "CORS max age in seconds for storage account"
  type        = number
  default     = 0
}

# Storage Container Names
variable "storage_container_invoices_name" {
  description = "Name of the storage container for invoices"
  type        = string
  default     = "invoices"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.storage_container_invoices_name))
    error_message = "Container name must be lowercase alphanumeric with hyphens, 3-63 characters."
  }
}

variable "storage_container_training_name" {
  description = "Name of the storage container for training data"
  type        = string
  default     = "training"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.storage_container_training_name))
    error_message = "Container name must be lowercase alphanumeric with hyphens, 3-63 characters."
  }
}

variable "storage_container_reports_name" {
  description = "Name of the storage container for reports"
  type        = string
  default     = "reports"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.storage_container_reports_name))
    error_message = "Container name must be lowercase alphanumeric with hyphens, 3-63 characters."
  }
}

variable "storage_container_access_type" {
  description = "Container access type (private or blob)"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "blob", "container"], var.storage_container_access_type)
    error_message = "Container access type must be one of: private, blob, container."
  }
}

# AI Services Network Configuration
variable "ai_services_public_network_access" {
  description = "Public network access for AI Services"
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.ai_services_public_network_access)
    error_message = "Public network access must be Enabled or Disabled."
  }
}

variable "ai_services_outbound_network_access_restricted" {
  description = "Restrict outbound network access for AI Services"
  type        = bool
  default     = false
}

variable "ai_services_local_auth_enabled" {
  description = "Enable local authentication for AI Services"
  type        = bool
  default     = true
}

# Key Vault Configuration
variable "key_vault_sku_name" {
  description = "SKU name for Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku_name)
    error_message = "Key Vault SKU must be either standard or premium."
  }
}

variable "enable_key_vault_rbac" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
  default     = true
}

variable "enable_key_vault_public_access" {
  description = "Enable public network access for Key Vault"
  type        = bool
  default     = true
}

# Language Service Configuration
variable "language_service_kind" {
  description = "Kind of Language Service (TextAnalytics)"
  type        = string
  default     = "TextAnalytics"
}

variable "enable_language_service_public_access" {
  description = "Enable public network access for Language Service"
  type        = bool
  default     = true
}

# ============================================================
# NETWORKING VARIABLES
# ============================================================

variable "enable_private_endpoints" {
  description = "Enable private endpoints for all Azure services"
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "Address space for Virtual Network (CIDR notation)"
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "VNet address space must not be empty."
  }
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix for private endpoints subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_gateway_subnet_prefix" {
  description = "Address prefix for application gateway subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for Azure Bastion subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "disable_public_network_access" {
  description = "Disable public network access for all resources (require private endpoints only)"
  type        = bool
  default     = false
}

variable "key_vault_allowed_ip_rules" {
  description = "List of IP addresses to allow access to Key Vault"
  type        = list(string)
  default     = []
}

variable "key_vault_allowed_subnet_ids" {
  description = "List of subnet IDs to allow access to Key Vault"
  type        = list(string)
  default     = []
}

variable "storage_account_allowed_ip_rules" {
  description = "List of IP addresses to allow access to Storage Account"
  type        = list(string)
  default     = []
}

variable "storage_account_allowed_subnet_ids" {
  description = "List of subnet IDs to allow access to Storage Account"
  type        = list(string)
  default     = []
}