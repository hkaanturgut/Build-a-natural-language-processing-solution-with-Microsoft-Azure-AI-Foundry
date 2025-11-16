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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Name of the storage account for datasets (must be globally unique)"
  type        = string
  default     = "stnlpdeveus001"
  
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