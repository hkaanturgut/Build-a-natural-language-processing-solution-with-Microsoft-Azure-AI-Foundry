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
    training = azurerm_storage_container.training.name
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

output "ai_services_key" {
  description = "Primary access key for Azure AI Services"
  value       = azurerm_ai_services.main.primary_access_key
  sensitive   = true
}

# Azure AI Language Service Outputs
output "language_service_name" {
  description = "Name of the Azure AI Language service"
  value       = azurerm_cognitive_account.language.name
}

output "language_service_id" {
  description = "ID of the Azure AI Language service"
  value       = azurerm_cognitive_account.language.id
}

output "language_service_endpoint" {
  description = "Endpoint of the Azure AI Language service"
  value       = azurerm_cognitive_account.language.endpoint
}

output "language_service_location" {
  description = "Location of the Azure AI Language service"
  value       = azurerm_cognitive_account.language.location
}

output "language_service_key" {
  description = "Primary access key for Azure AI Language service"
  value       = azurerm_cognitive_account.language.primary_access_key
  sensitive   = true
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
    language_service_id       = azurerm_key_vault_secret.language_service_id.name
    language_service_endpoint = azurerm_key_vault_secret.language_service_endpoint.name
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
    language_service    = azurerm_cognitive_account.language.name
    ai_services         = azurerm_ai_services.main.name
    environment         = var.environment
  }
}

# Storage connection string for .env generation
output "storage_connection_string" {
  description = "Azure Storage connection string"
  value       = azurerm_storage_account.datasets.primary_connection_string
  sensitive   = true
}

# .env file generation
output "env_file_path" {
  description = "Path to the generated .env file"
  value       = local_file.env_file.filename
}

# Uploaded data files
output "uploaded_data_files" {
  description = "Information about uploaded data files"
  value = {
    invoices_data = {
      name = azurerm_storage_blob.invoices_data.name
      url  = azurerm_storage_blob.invoices_data.url
    }
    pii_samples_data = {
      name = azurerm_storage_blob.pii_samples_data.name
      url  = azurerm_storage_blob.pii_samples_data.url
    }
    clu_training_data = {
      name = azurerm_storage_blob.clu_training_data.name
      url  = azurerm_storage_blob.clu_training_data.url
    }
  }
}