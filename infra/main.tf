# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-ai-${local.location_short[var.location]}-${var.environment}-001"
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
  name                  = "invoices"
  storage_account_id    = azurerm_storage_account.datasets.id
  container_access_type = "private"

  depends_on = [azurerm_storage_account.datasets]
}

resource "azurerm_storage_container" "training" {
  name                  = "training"
  storage_account_id    = azurerm_storage_account.datasets.id
  container_access_type = "private"

  depends_on = [azurerm_storage_account.datasets]
}


resource "azurerm_storage_container" "reports" {
  name                  = "reports"
  storage_account_id    = azurerm_storage_account.datasets.id
  container_access_type = "private"

  depends_on = [azurerm_storage_account.datasets]
}

# Deploy Azure AI Services resource
resource "azurerm_ai_services" "main" {
  name                = "ais-${var.environment}-${local.location_short[var.location]}-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "S0"

  # Set custom subdomain for API access
  custom_subdomain_name = "ais-${var.environment}-${local.location_short[var.location]}-001"

  # Network and authentication settings
  public_network_access              = "Enabled"
  outbound_network_access_restricted = false
  local_authentication_enabled       = true

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Deploy Azure Key Vault with RBAC
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.environment}-${local.location_short[var.location]}-ai-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable RBAC authorization instead of access policies
  rbac_authorization_enabled     = true
  public_network_access_enabled = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Grant Key Vault Administrator role to current user



resource "azurerm_cognitive_account" "language" {
  name                = "lang-${var.environment}-${local.location_short[var.location]}-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "TextAnalytics"
  sku_name            = "S"

  # Enable Custom features (NER, CLU)
  custom_subdomain_name = "lang-${var.environment}-${local.location_short[var.location]}-001"

  # Network settings
  public_network_access_enabled = true

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

# Deploy Azure AI Foundry
resource "azurerm_ai_foundry" "main" {
  name                = "aif-${var.environment}-${local.location_short[var.location]}-001"
  location            = azurerm_resource_group.main.location
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

    azurerm_storage_account.datasets,
    azurerm_key_vault.main,
    azurerm_role_assignment.current_user_kv_admin
  ]
}



# Deploy Azure AI Foundry Project
resource "azurerm_ai_foundry_project" "main" {
  name               = "aifp-${var.environment}-${local.location_short[var.location]}-001"
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
  type       = "Microsoft.CognitiveServices/accounts/deployments@2023-05-01"
  name       = "gpt-5-chat"
  parent_id  = azurerm_ai_services.main.id
  depends_on = [
    azurerm_ai_services.main,
    azurerm_ai_foundry.main
  ]

  body = {
    sku = {
      name     = "GlobalStandard"
      capacity = 1
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = "gpt-5-chat"
        version = "2025-10-03"
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
  name                   = "invoices.txt"
  storage_account_name   = azurerm_storage_account.datasets.name
  storage_container_name = azurerm_storage_container.invoices.name
  type                   = "Block"
  source                 = "${path.module}/../data/invoices.txt"
  content_type           = "text/plain"

  depends_on = [azurerm_storage_container.invoices]
}

resource "azurerm_storage_blob" "pii_samples_data" {
  name                   = "pii_samples.txt"
  storage_account_name   = azurerm_storage_account.datasets.name
  storage_container_name = azurerm_storage_container.training.name
  type                   = "Block"
  source                 = "${path.module}/../data/pii_samples.txt"
  content_type           = "text/plain"

  depends_on = [azurerm_storage_container.training]
}

resource "azurerm_storage_blob" "clu_training_data" {
  name                   = "clu_training_utterances.md"
  storage_account_name   = azurerm_storage_account.datasets.name
  storage_container_name = azurerm_storage_container.training.name
  type                   = "Block"
  source                 = "${path.module}/../data/clu_training_utterances.md"
  content_type           = "text/markdown"

  depends_on = [azurerm_storage_container.training]
}

# Seamless automation: update .env file with Key Vault URI after apply
resource "null_resource" "update_env_file" {
  provisioner "local-exec" {
    command = "${path.module}/../update-env.sh"
  }

  triggers = {
    key_vault_uri = azurerm_key_vault.main.vault_uri
  }
}

# resource "azapi_resource" "language_service_connection" {
#   type      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
#   name      = "language-service-connection"
#   parent_id = azurerm_cognitive_account.language.id
#   location  = azurerm_resource_group.main.location

#   body = {
#     properties = {
#       category    = "CognitiveService"
#       authType    = "ApiKey"
#       target      = azurerm_cognitive_account.language.endpoint
#       credentials = {
#         key = azurerm_cognitive_account.language.primary_access_key
#       }
#       # Optionally add metadata, expiryTime, etc.
#     }
#   }
#   depends_on = [azurerm_cognitive_account.language]
# }

