resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = "8b24774c-70ab-427a-9d6f-8ee5d038b6e3"
  depends_on           = [azurerm_key_vault.main]
}

# Grant Storage Blob Data Contributor to current user on storage account
# The user must have "Storage Blob Data Contributor" role in the Azure Blob storage account to run Custom Text Classification
resource "azurerm_role_assignment" "current_user_storage_blob_contributor" {
  scope                = azurerm_storage_account.datasets.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "8b24774c-70ab-427a-9d6f-8ee5d038b6e3"
  depends_on           = [azurerm_storage_account.datasets]
}

# Grant Storage Blob Data Contributor role to language service managed identity
resource "azurerm_role_assignment" "language_storage_blob_contributor" {
  scope                = azurerm_storage_account.datasets.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_cognitive_account.language.identity[0].principal_id

  depends_on = [azurerm_cognitive_account.language]
}
resource "azurerm_role_assignment" "language_storage_blob_owner" {
  scope                = azurerm_storage_account.datasets.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_cognitive_account.language.identity[0].principal_id
  depends_on           = [azurerm_cognitive_account.language, azurerm_storage_account.datasets]
}

resource "azurerm_role_assignment" "language_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_cognitive_account.language.identity[0].principal_id
  depends_on           = [azurerm_cognitive_account.language]
}

resource "azurerm_role_assignment" "ai_foundry_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_ai_foundry.main.identity[0].principal_id
  depends_on           = [azurerm_ai_foundry.main]
}

resource "azurerm_role_assignment" "ai_foundry_project_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_ai_foundry_project.main.identity[0].principal_id
  depends_on           = [azurerm_ai_foundry_project.main]
}

# Grant Language Service permissions to current user for project access
resource "azurerm_role_assignment" "current_user_language_owner" {
  scope                = azurerm_cognitive_account.language.id
  role_definition_name = "Cognitive Services Language Owner"
  principal_id         = "8b24774c-70ab-427a-9d6f-8ee5d038b6e3"
  depends_on           = [azurerm_cognitive_account.language]
}

# # Grant Storage Blob Data Contributor to Language Service managed identity
# resource "azurerm_role_assignment" "language_storage_blob_contributor" {
#   scope                = azurerm_storage_account.datasets.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_cognitive_account.language.identity[0].principal_id
#   depends_on           = [azurerm_cognitive_account.language, azurerm_storage_account.datasets]
# }

# # Grant Storage Blob Data Contributor to current user
# resource "azurerm_role_assignment" "current_user_storage_blob_contributor" {
#   scope                = azurerm_storage_account.datasets.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = "8b24774c-70ab-427a-9d6f-8ee5d038b6e3"
#   depends_on           = [azurerm_storage_account.datasets]
# }

