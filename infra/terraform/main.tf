# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-nlp-${local.location_short[var.location]}-${var.environment}-01"
  location = var.location
  tags     = var.tags
}

# Create Storage Account for AI Foundry
resource "azurerm_storage_account" "datasets" {
  name                     = "stnlp${var.environment}${local.location_short[var.location]}01"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = var.storage_account_kind

  # Security settings
  https_traffic_only_enabled      = var.enable_storage_https_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_storage_nested_public_access
  public_network_access_enabled   = !var.disable_public_network_access

  # Enable blob versioning and soft delete
  blob_properties {
    versioning_enabled  = var.enable_blob_versioning
    change_feed_enabled = var.enable_blob_change_feed

    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }

    cors_rule {
      allowed_headers    = var.storage_cors_allowed_headers
      allowed_methods    = var.storage_cors_allowed_methods
      allowed_origins    = var.storage_cors_allowed_origins
      exposed_headers    = var.storage_cors_exposed_headers
      max_age_in_seconds = var.storage_cors_max_age_seconds
    }
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}
# Location code variable

locals {
  location_short = {
    "East US"        = "eus"
    "East US 2"      = "eus2"
    "Central US"     = "cus"
    "West US"        = "wus"
    "West US 2"      = "wus2"
    "North Europe"   = "neu"
    "West Europe"    = "weu"
    "Southeast Asia" = "sea"
    "East Asia"      = "eas"
  }
}
variable "location_code" {
  type    = string
  default = "eus2"
}
# Create containers for different data types
resource "azurerm_storage_container" "invoices" {
  name                  = var.storage_container_invoices_name
  storage_account_id    = azurerm_storage_account.datasets.id
  container_access_type = var.storage_container_access_type

  depends_on = [azurerm_storage_account.datasets]
}

resource "azurerm_storage_container" "reports" {
  name                  = var.storage_container_reports_name
  storage_account_id    = azurerm_storage_account.datasets.id
  container_access_type = var.storage_container_access_type

  depends_on = [azurerm_storage_account.datasets]
}

# Deploy Azure AI Services resource
resource "azurerm_ai_services" "main" {
  name                = "ais-${var.environment}-${local.location_short[var.location]}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.ai_services_sku

  # Set custom subdomain for API access
  custom_subdomain_name = "ais-${var.environment}-${local.location_short[var.location]}-01"

  # Network and authentication settings
  public_network_access              = var.disable_public_network_access ? "Disabled" : "Enabled"
  outbound_network_access_restricted = var.ai_services_outbound_network_access_restricted
  local_authentication_enabled       = var.ai_services_local_auth_enabled

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Deploy Azure Key Vault with RBAC
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.environment}-${local.location_short[var.location]}-ai-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku_name

  # Enable RBAC authorization instead of access policies
  rbac_authorization_enabled    = var.enable_key_vault_rbac
  public_network_access_enabled = !var.disable_public_network_access
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Grant Key Vault Administrator role to current user



resource "azurerm_cognitive_account" "language" {
  name                = "lang-${var.environment}-${local.location_short[var.location]}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = var.language_service_kind
  sku_name            = var.language_service_sku

  # Enable Custom features (NER, CLU)
  custom_subdomain_name = "lang-${var.environment}-${local.location_short[var.location]}-01"

  # Network settings
  public_network_access_enabled = !var.disable_public_network_access

  storage {
    storage_account_id = azurerm_storage_account.datasets.id
  }
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

resource "azurerm_key_vault_secret" "language_service_id" {
  name         = "language-service-id"
  value        = azurerm_cognitive_account.language.id
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_cognitive_account.language
  ]
}

resource "azurerm_key_vault_secret" "language_service_endpoint" {
  name         = "language-service-endpoint"
  value        = azurerm_cognitive_account.language.endpoint
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_cognitive_account.language
  ]
}

resource "azurerm_key_vault_secret" "language_service_key" {
  name         = "language-service-key"
  value        = azurerm_cognitive_account.language.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_cognitive_account.language
  ]
}

# Deploy Azure AI Foundry
resource "azurerm_ai_foundry" "main" {
  name                = "aif-${var.environment}-${local.location_short[var.location]}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Associate with storage and key vault
  storage_account_id = azurerm_storage_account.datasets.id
  key_vault_id       = azurerm_key_vault.main.id

  # Network settings
  public_network_access = var.disable_public_network_access ? "Disabled" : "Enabled"

  # Managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [

    azurerm_storage_account.datasets,
    azurerm_key_vault.main,
    azurerm_role_assignment.current_user_kv_admin
  ]

  lifecycle {
    ignore_changes = [tags]
  }
}



# Deploy Azure AI Foundry Project
resource "azurerm_ai_foundry_project" "main" {
  name               = "aifp-${var.environment}-${local.location_short[var.location]}-01"
  location           = azurerm_resource_group.main.location
  ai_services_hub_id = azurerm_ai_foundry.main.id

  # Managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [azurerm_ai_foundry.main]
}

# Deploy GPT-5-Chat model in AI Foundry using azapi_resource
resource "azapi_resource" "aifoundry_deployment_gpt_5_chat" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@${var.ai_services_api_version}"
  name      = var.gpt_model_deployment_name
  parent_id = azurerm_ai_services.main.id
  depends_on = [
    azurerm_ai_services.main,
    azurerm_ai_foundry.main
  ]

  body = {
    sku = {
      name     = var.gpt_deployment_sku_name
      capacity = var.gpt_deployment_sku_capacity
    }
    properties = {
      model = {
        format  = var.gpt_model_format
        name    = var.gpt_model_name
        version = var.gpt_model_version
      }
    }
  }
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

# Add GPT-5 Chat model secrets for Python usage
resource "azurerm_key_vault_secret" "gpt_5_chat_key" {
  name         = "gpt-5-chat-key"
  value        = azurerm_ai_services.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_ai_services.main
  ]
}

resource "azurerm_key_vault_secret" "gpt_5_chat_endpoint" {
  name         = "gpt-5-chat-endpoint"
  value        = "https://${azurerm_ai_services.main.name}.cognitiveservices.azure.com/"
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azapi_resource.aifoundry_deployment_gpt_5_chat
  ]
}

resource "azurerm_key_vault_secret" "key_vault_uri" {
  name         = "key-vault-uri"
  value        = azurerm_key_vault.main.vault_uri
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.current_user_kv_admin,
    azurerm_key_vault.main
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

# Generate .env file for Python applications automatically

# Upload data files to appropriate storage containers
resource "azurerm_storage_blob" "invoices_data" {
  for_each = fileset("${path.module}/../data/invoices", "*.txt")

  name                   = each.value
  storage_account_name   = azurerm_storage_account.datasets.name
  storage_container_name = azurerm_storage_container.invoices.name
  type                   = "Block"
  source                 = "${path.module}/../data/invoices/${each.value}"
  content_type           = "text/plain"

  depends_on = [azurerm_storage_container.invoices]
}


# Seamless automation: update .env file with Key Vault URI after apply
resource "null_resource" "update_env_file" {
  provisioner "local-exec" {
    command = "${path.module}/../update-env.sh"
  }

  triggers = {
    key_vault_uri = azurerm_key_vault.main.vault_uri
  }

  depends_on = [azurerm_key_vault.main]
}

