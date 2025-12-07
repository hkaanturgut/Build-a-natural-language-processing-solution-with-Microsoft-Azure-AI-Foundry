# ============================================================
# NETWORKING CONFIGURATION - Virtual Network & Private Endpoints
# ============================================================

# Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}-${local.location_short[var.location]}-ai-01"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(
    var.tags,
    {
      Name        = "vnet-${var.environment}-${local.location_short[var.location]}-ai-01"
      Description = "Virtual Network for AI Foundry resources"
    }
  )

  depends_on = [azurerm_resource_group.main]
}

# ============================================================
# SUBNETS
# ============================================================

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                = "snet-${var.environment}-${local.location_short[var.location]}-pe-01"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes    = ["10.0.1.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.CognitiveServices"
  ]

  depends_on = [azurerm_virtual_network.main]
}

# Subnet for Application Gateway / Bastion (if needed)
resource "azurerm_subnet" "app_gateway" {
  name                = "snet-${var.environment}-${local.location_short[var.location]}-appgw-01"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes    = ["10.0.2.0/24"]

  depends_on = [azurerm_virtual_network.main]
}

# Subnet for Bastion Host (for secure management)
resource "azurerm_subnet" "bastion" {
  name                = "AzureBastionSubnet"  # Must be named exactly this for Bastion
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes    = ["10.0.3.0/24"]

  depends_on = [azurerm_virtual_network.main]
}

# ============================================================
# NETWORK SECURITY GROUPS
# ============================================================

# NSG for Private Endpoints Subnet
resource "azurerm_network_security_group" "private_endpoints_nsg" {
  name                = "nsg-${var.environment}-${local.location_short[var.location]}-pe-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS traffic within VNet
  security_rule {
    name                       = "AllowHTTPSFromVNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow DNS from VNet
  security_rule {
    name                       = "AllowDNSFromVNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic to Azure services
  security_rule {
    name                       = "AllowOutboundToAzure"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Associate NSG with Private Endpoints Subnet
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints_nsg.id
}

# NSG for Application Gateway Subnet
resource "azurerm_network_security_group" "app_gateway_nsg" {
  name                = "nsg-${var.environment}-${local.location_short[var.location]}-appgw-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS inbound
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow HTTP inbound (optional)
  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Associate NSG with Application Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  subnet_id                 = azurerm_subnet.app_gateway.id
  network_security_group_id = azurerm_network_security_group.app_gateway_nsg.id
}

# ============================================================
# PRIVATE DNS ZONES
# ============================================================

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Private DNS Zone for Cognitive Services
resource "azurerm_private_dns_zone" "cognitive" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Link Private DNS Zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "link-storage-${var.environment}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  depends_on = [azurerm_private_dns_zone.storage]
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-keyvault-${var.environment}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  depends_on = [azurerm_private_dns_zone.keyvault]
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive" {
  name                  = "link-cognitive-${var.environment}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  depends_on = [azurerm_private_dns_zone.cognitive]
}

# ============================================================
# PRIVATE ENDPOINTS - STORAGE ACCOUNT
# ============================================================

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-${var.environment}-${local.location_short[var.location]}-storage-blob-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.datasets.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                           = "dns-group-storage-blob"
    private_dns_zone_ids           = [azurerm_private_dns_zone.storage.id]
  }

  tags = var.tags

  depends_on = [azurerm_storage_account.datasets, azurerm_subnet.private_endpoints]
}

# ============================================================
# PRIVATE ENDPOINTS - KEY VAULT
# ============================================================

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${var.environment}-${local.location_short[var.location]}-kv-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                           = "dns-group-keyvault"
    private_dns_zone_ids           = [azurerm_private_dns_zone.keyvault.id]
  }

  tags = var.tags

  depends_on = [azurerm_key_vault.main, azurerm_subnet.private_endpoints]
}

# ============================================================
# PRIVATE ENDPOINTS - LANGUAGE SERVICE
# ============================================================

resource "azurerm_private_endpoint" "language_service" {
  name                = "pe-${var.environment}-${local.location_short[var.location]}-lang-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-language-service"
    private_connection_resource_id = azurerm_cognitive_account.language.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                           = "dns-group-language"
    private_dns_zone_ids           = [azurerm_private_dns_zone.cognitive.id]
  }

  tags = var.tags

  depends_on = [azurerm_cognitive_account.language, azurerm_subnet.private_endpoints]
}

# ============================================================
# PRIVATE ENDPOINTS - AI SERVICES
# ============================================================

resource "azurerm_private_endpoint" "ai_services" {
  name                = "pe-${var.environment}-${local.location_short[var.location]}-ais-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-ai-services"
    private_connection_resource_id = azurerm_ai_services.main.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                           = "dns-group-ai-services"
    private_dns_zone_ids           = [azurerm_private_dns_zone.cognitive.id]
  }

  tags = var.tags

  depends_on = [azurerm_ai_services.main, azurerm_subnet.private_endpoints]
}

# ============================================================
# UPDATE STORAGE ACCOUNT - DISABLE PUBLIC ACCESS
# ============================================================

# Disable public network access on storage account (only private endpoints allowed)
resource "azurerm_storage_account_network_rules" "datasets" {
  storage_account_id = azurerm_storage_account.datasets.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = [azurerm_subnet.private_endpoints.id]

  depends_on = [
    azurerm_storage_account.datasets,
    azurerm_private_endpoint.storage_blob
  ]
}

# ============================================================
# OUTPUT NETWORKING INFORMATION
# ============================================================

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "private_endpoints_subnet_id" {
  description = "ID of the Private Endpoints Subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "private_endpoints_subnet_name" {
  description = "Name of the Private Endpoints Subnet"
  value       = azurerm_subnet.private_endpoints.name
}

output "storage_private_endpoint_id" {
  description = "ID of the Storage Account Private Endpoint"
  value       = azurerm_private_endpoint.storage_blob.id
}

output "keyvault_private_endpoint_id" {
  description = "ID of the Key Vault Private Endpoint"
  value       = azurerm_private_endpoint.keyvault.id
}

output "language_service_private_endpoint_id" {
  description = "ID of the Language Service Private Endpoint"
  value       = azurerm_private_endpoint.language_service.id
}

output "ai_services_private_endpoint_id" {
  description = "ID of the AI Services Private Endpoint"
  value       = azurerm_private_endpoint.ai_services.id
}

output "private_dns_zone_storage_id" {
  description = "ID of the Private DNS Zone for Storage"
  value       = azurerm_private_dns_zone.storage.id
}

output "private_dns_zone_keyvault_id" {
  description = "ID of the Private DNS Zone for Key Vault"
  value       = azurerm_private_dns_zone.keyvault.id
}

output "private_dns_zone_cognitive_id" {
  description = "ID of the Private DNS Zone for Cognitive Services"
  value       = azurerm_private_dns_zone.cognitive.id
}
