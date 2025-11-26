resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.main]
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
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_cognitive_account.language]
}

