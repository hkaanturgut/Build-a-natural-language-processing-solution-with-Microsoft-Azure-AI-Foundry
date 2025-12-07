# Production environment configuration

subscription_id = "52513787-3db1-4afb-845e-922fd437040e"
environment     = "prod"
location        = "East US 2"

# Storage account name for datasets (must be globally unique, 3-24 chars, lowercase letters and numbers only)
storage_account_name = "stnlpprodeus001"

# Storage account configuration
storage_account_tier             = "Standard"
storage_account_replication_type = "GRS"
storage_account_kind             = "StorageV2"
min_tls_version                  = "TLS1_2"
blob_soft_delete_retention_days  = 30
container_soft_delete_retention_days = 30

# Storage Account Features
enable_storage_https_only              = true
enable_storage_public_access           = false
allow_storage_nested_public_access     = false
enable_blob_versioning                 = true
enable_blob_change_feed                = true

# CORS Configuration for Storage
storage_cors_allowed_headers   = ["Authorization", "Content-Type", "x-ms-blob-type", "x-ms-version"]
storage_cors_allowed_methods   = ["GET", "HEAD", "POST", "PUT", "OPTIONS"]
storage_cors_allowed_origins   = []
storage_cors_exposed_headers   = ["x-ms-request-id", "x-ms-version", "Date"]
storage_cors_max_age_seconds   = 3600

# Storage Container Names
storage_container_invoices_name = "invoices"
storage_container_training_name = "training"
storage_container_reports_name  = "reports"
storage_container_access_type   = "private"

# Azure AI Foundry workspace name
ai_foundry_workspace_name = "aif-nlp-ai-foundry-prod"

# AI Services configuration
ai_services_sku = "S0"

# Key Vault configuration
key_vault_name = "kv-nlp-prod"
