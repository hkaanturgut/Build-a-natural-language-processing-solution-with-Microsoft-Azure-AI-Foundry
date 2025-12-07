variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "qa"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "storage_account_name" {
  description = "Name of the storage account for datasets (must be globally unique)"
  type        = string
}

variable "ai_foundry_workspace_name" {
  description = "Name of the Azure AI Foundry workspace"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "QAT"
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
}

variable "storage_account_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
}

variable "storage_account_kind" {
  description = "Storage account kind (StorageV2 or BlobStorage)"
  type        = string
  default     = "StorageV2"
}

variable "min_tls_version" {
  description = "Minimum TLS version for storage account"
  type        = string
  default     = "TLS1_2"
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted blobs"
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted containers"
  type        = number
  default     = 7
}

variable "enable_storage_https_only" {
  description = "Enable HTTPS only for storage account"
  type        = bool
  default     = true
}

variable "enable_storage_public_access" {
  description = "Enable public network access to storage account"
  type        = bool
  default     = true
}

variable "disable_public_network_access" {
  description = "Disable public network access to storage account"
  type        = bool
  default     = false
}

variable "allow_storage_nested_public_access" {
  description = "Allow nested items to be public in storage account"
  type        = bool
  default     = false
}

variable "enable_blob_versioning" {
  description = "Enable blob versioning in storage account"
  type        = bool
  default     = true
}

variable "enable_blob_change_feed" {
  description = "Enable blob change feed in storage account"
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
  default     = ["GET", "HEAD", "POST", "PUT", "OPTIONS"]
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
}

variable "storage_container_training_name" {
  description = "Name of the storage container for training data"
  type        = string
  default     = "training"
}

variable "storage_container_reports_name" {
  description = "Name of the storage container for reports"
  type        = string
  default     = "reports"
}

variable "storage_container_access_type" {
  description = "Access type for storage containers (private or blob)"
  type        = string
  default     = "private"
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
}