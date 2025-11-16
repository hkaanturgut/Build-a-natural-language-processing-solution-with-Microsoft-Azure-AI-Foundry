# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.main.location
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the datasets storage account"
  value       = azurerm_storage_account.datasets.name
}

output "storage_account_id" {
  description = "ID of the datasets storage account"
  value       = azurerm_storage_account.datasets.id
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint for the storage account"
  value       = azurerm_storage_account.datasets.primary_blob_endpoint
}

output "storage_containers" {
  description = "Names of the created storage containers"
  value = {
    invoices = azurerm_storage_container.invoices.name
    logs     = azurerm_storage_container.logs.name
    models   = azurerm_storage_container.models.name
  }
}

# Azure AI Services Outputs
output "ai_services_name" {
  description = "Name of the Azure AI Services resource"
  value       = azurerm_ai_services.main.name
}

output "ai_services_endpoint" {
  description = "Endpoint for the Azure AI Services resource"
  value       = azurerm_ai_services.main.endpoint
}

output "ai_services_id" {
  description = "ID of the Azure AI Services resource"
  value       = azurerm_ai_services.main.id
}

# Azure AI Foundry Outputs
output "ai_foundry_name" {
  description = "Name of the Azure AI Foundry service"
  value       = azurerm_ai_foundry.main.name
}

output "ai_foundry_id" {
  description = "ID of the Azure AI Foundry service"
  value       = azurerm_ai_foundry.main.id
}

output "ai_foundry_location" {
  description = "Location of the Azure AI Foundry service"
  value       = azurerm_ai_foundry.main.location
}

# Azure AI Foundry Project Outputs
output "ai_foundry_project_name" {
  description = "Name of the Azure AI Foundry project"
  value       = azurerm_ai_foundry_project.main.name
}

output "ai_foundry_project_id" {
  description = "ID of the Azure AI Foundry project"
  value       = azurerm_ai_foundry_project.main.id
}

# Key Vault Outputs
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

# Secret Names (for reference in applications)
output "secret_names" {
  description = "Names of secrets stored in Key Vault"
  value = {
    ai_foundry_id             = azurerm_key_vault_secret.ai_foundry_id.name
    ai_foundry_project_id     = azurerm_key_vault_secret.ai_foundry_project_id.name
    ai_services_endpoint      = azurerm_key_vault_secret.ai_services_endpoint.name
    storage_connection_string = azurerm_key_vault_secret.storage_connection_string.name
  }
}

# Useful connection information
output "connection_info" {
  description = "Connection information for applications"
  value = {
    resource_group      = azurerm_resource_group.main.name
    key_vault_name      = azurerm_key_vault.main.name
    storage_account     = azurerm_storage_account.datasets.name
    ai_foundry_service  = azurerm_ai_foundry.main.name
    ai_foundry_project  = azurerm_ai_foundry_project.main.name
    ai_services         = azurerm_ai_services.main.name
    environment         = var.environment
  }
}