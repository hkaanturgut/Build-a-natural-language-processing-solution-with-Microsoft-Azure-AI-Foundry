# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Location mapping for short names
locals {
  location_short = {
    "East US"    = "eus"
    "West US"    = "wus"
    "East US 2"  = "eus2"
    "West US 2"  = "wus2"
    "Central US" = "cus"
  }
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-nlp-ai-foundry-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Create Storage Account for AI Foundry
resource "azurerm_storage_account" "datasets" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Security settings
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  # Enable blob versioning and soft delete
  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
  
  depends_on = [azurerm_resource_group.main]
}

# Create containers for different data types
resource "azurerm_storage_container" "invoices" {
  name                 = "invoices"
  storage_account_name = azurerm_storage_account.datasets.name
  container_access_type = "private"
  
  depends_on = [azurerm_storage_account.datasets]
}

resource "azurerm_storage_container" "logs" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.datasets.name
  container_access_type = "private"
  
  depends_on = [azurerm_storage_account.datasets]
}

resource "azurerm_storage_container" "models" {
  name                 = "models"
  storage_account_name = azurerm_storage_account.datasets.name
  container_access_type = "private"
  
  depends_on = [azurerm_storage_account.datasets]
}

# Deploy Azure AI Services resource
resource "azurerm_ai_services" "main" {
  name                = "ais-nlp-dev-${local.location_short[var.location]}-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "S0"

  # Set custom subdomain for API access
  custom_subdomain_name = "ais-nlp-dev-${local.location_short[var.location]}-001"

  # Network and authentication settings
  public_network_access                 = "Enabled"
  outbound_network_access_restricted    = false
  local_authentication_enabled          = true

  tags = var.tags
  
  depends_on = [azurerm_resource_group.main]
}

# Deploy Azure Key Vault with RBAC
resource "azurerm_key_vault" "main" {
  name                = "kv-nlp-dev-${local.location_short[var.location]}-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable RBAC authorization instead of access policies
  enable_rbac_authorization     = true
  public_network_access_enabled = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90

  tags = var.tags
  
  depends_on = [azurerm_resource_group.main]
}

# Grant Key Vault Administrator role to current user
resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
  
  depends_on = [azurerm_key_vault.main]
}

# Deploy Azure AI Foundry
resource "azurerm_ai_foundry" "main" {
  name                = "aif-nlp-dev-${local.location_short[var.location]}-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Associate with storage and key vault
  storage_account_id = azurerm_storage_account.datasets.id
  key_vault_id       = azurerm_key_vault.main.id

  # Network settings
  public_network_access = "Enabled"

  # Managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_resource_group.main,
    azurerm_storage_account.datasets,
    azurerm_key_vault.main,
    azurerm_role_assignment.current_user_kv_admin
  ]
}

# Grant Key Vault Secrets User role to AI Foundry managed identity
resource "azurerm_role_assignment" "ai_foundry_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_ai_foundry.main.identity[0].principal_id

  depends_on = [azurerm_ai_foundry.main]
}

# Deploy Azure AI Foundry Project
resource "azurerm_ai_foundry_project" "main" {
  name                  = "aifp-nlp-dev-${local.location_short[var.location]}-001"
  location              = var.location
  ai_services_hub_id    = azurerm_ai_foundry.main.id

  # Managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
  
  depends_on = [azurerm_ai_foundry.main]
}

# Grant Key Vault Secrets User role to AI Foundry Project managed identity
resource "azurerm_role_assignment" "ai_foundry_project_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_ai_foundry_project.main.identity[0].principal_id

  depends_on = [azurerm_ai_foundry_project.main]
}

# Store important information in Key Vault
resource "azurerm_key_vault_secret" "ai_foundry_id" {
  name         = "ai-foundry-id"
  value        = azurerm_ai_foundry.main.id
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_ai_foundry.main
  ]
}

resource "azurerm_key_vault_secret" "ai_foundry_project_id" {
  name         = "ai-foundry-project-id"
  value        = azurerm_ai_foundry_project.main.id
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_ai_foundry_project.main
  ]
}

resource "azurerm_key_vault_secret" "ai_services_endpoint" {
  name         = "ai-services-endpoint"
  value        = azurerm_ai_services.main.endpoint
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_ai_services.main
  ]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.datasets.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_storage_account.datasets
  ]
}