module "nlp" {
  source = "../terraform"

  # Core variables
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

  # Storage Account Configuration
  storage_account_name             = var.storage_account_name
  storage_account_tier             = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
  storage_account_kind             = var.storage_account_kind
  min_tls_version                  = var.min_tls_version
  blob_soft_delete_retention_days  = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days

  # Storage Account Features
  enable_storage_https_only          = var.enable_storage_https_only
  disable_public_network_access      = var.disable_public_network_access
  allow_storage_nested_public_access = var.allow_storage_nested_public_access
  enable_blob_versioning             = var.enable_blob_versioning
  enable_blob_change_feed            = var.enable_blob_change_feed

  # CORS Configuration
  storage_cors_allowed_headers   = var.storage_cors_allowed_headers
  storage_cors_allowed_methods   = var.storage_cors_allowed_methods
  storage_cors_allowed_origins   = var.storage_cors_allowed_origins
  storage_cors_exposed_headers   = var.storage_cors_exposed_headers
  storage_cors_max_age_seconds   = var.storage_cors_max_age_seconds

  # Storage Container Names
  storage_container_invoices_name = var.storage_container_invoices_name
  storage_container_training_name = var.storage_container_training_name
  storage_container_reports_name  = var.storage_container_reports_name
  storage_container_access_type   = var.storage_container_access_type

  # AI Services
  ai_foundry_workspace_name = var.ai_foundry_workspace_name
  ai_services_sku           = var.ai_services_sku
  language_service_sku      = var.language_service_sku

  # Key Vault
  key_vault_name = var.key_vault_name

  # Tags
  tags = var.tags
}