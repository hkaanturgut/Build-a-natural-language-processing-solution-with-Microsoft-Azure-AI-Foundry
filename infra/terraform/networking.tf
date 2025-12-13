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
  name                 = "snet-${var.environment}-${local.location_short[var.location]}-pe-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.CognitiveServices"
  ]

  depends_on = [azurerm_virtual_network.main]
}

# Subnet for Application Gateway / Bastion (if needed)
resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-${var.environment}-${local.location_short[var.location]}-appgw-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [azurerm_virtual_network.main]
}

# Subnet for Bastion Host (for secure management)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet" # Must be named exactly this for Bastion
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  depends_on = [azurerm_virtual_network.main]
}

# Subnet for GitHub Hosted Runners
resource "azurerm_subnet" "github_hosted_runners" {
  name                 = "github-hosted-runners"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/27"]

  delegation {
    name = "github-network-settings"
    service_delegation {
      name    = "GitHub.Network/networkSettings"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

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

# NSG for GitHub Hosted Runners Subnet
resource "azurerm_network_security_group" "github_runners_nsg" {
  name                = "nsg-${var.environment}-${local.location_short[var.location]}-github-runners-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow VNet outbound on port 443
  security_rule {
    name                       = "AllowVnetOutBoundOverwrite"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow outbound to GitHub Actions service IPs
  security_rule {
    name                   = "AllowOutBoundActions"
    priority               = 210
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "443"
    source_address_prefix  = "*"
    destination_address_prefixes = [
      "4.175.114.51/32",
      "20.102.35.120/32",
      "4.175.114.43/32",
      "20.72.125.48/32",
      "20.19.5.100/32",
      "20.7.92.46/32",
      "20.232.252.48/32",
      "52.186.44.51/32",
      "20.22.98.201/32",
      "20.246.184.240/32",
      "20.96.133.71/32",
      "20.253.2.203/32",
      "20.102.39.220/32",
      "20.81.127.181/32",
      "52.148.30.208/32",
      "20.14.42.190/32",
      "20.85.159.192/32",
      "52.224.205.173/32",
      "20.118.176.156/32",
      "20.236.207.188/32",
      "20.242.161.191/32",
      "20.166.216.139/32",
      "20.253.126.26/32",
      "52.152.245.137/32",
      "40.118.236.116/32",
      "20.185.75.138/32",
      "20.96.226.211/32",
      "52.167.78.33/32",
      "20.105.13.142/32",
      "20.253.95.3/32",
      "20.221.96.90/32",
      "51.138.235.85/32",
      "52.186.47.208/32",
      "20.7.220.66/32",
      "20.75.4.210/32",
      "20.120.75.171/32",
      "20.98.183.48/32",
      "20.84.200.15/32",
      "20.14.235.135/32",
      "20.10.226.54/32",
      "20.22.166.15/32",
      "20.65.21.88/32",
      "20.102.36.236/32",
      "20.124.56.57/32",
      "20.94.100.174/32",
      "20.102.166.33/32",
      "20.31.193.160/32",
      "20.232.77.7/32",
      "20.102.38.122/32",
      "20.102.39.57/32",
      "20.85.108.33/32",
      "40.88.240.168/32",
      "20.69.187.19/32",
      "20.246.192.124/32",
      "20.4.161.108/32",
      "20.22.22.84/32",
      "20.1.250.47/32",
      "20.237.33.78/32",
      "20.242.179.206/32",
      "40.88.239.133/32",
      "20.121.247.125/32",
      "20.106.107.180/32",
      "20.22.118.40/32",
      "20.15.240.48/32",
      "20.84.218.150/32"
    ]
  }

  # Allow outbound to GitHub
  security_rule {
    name                   = "AllowOutBoundGitHub"
    priority               = 220
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "443"
    source_address_prefix  = "*"
    destination_address_prefixes = [
      "140.82.112.0/20",
      "143.55.64.0/20",
      "185.199.108.0/22",
      "192.30.252.0/22",
      "20.175.192.146/32",
      "20.175.192.147/32",
      "20.175.192.149/32",
      "20.175.192.150/32",
      "20.199.39.227/32",
      "20.199.39.228/32",
      "20.199.39.231/32",
      "20.199.39.232/32",
      "20.200.245.241/32",
      "20.200.245.245/32",
      "20.200.245.246/32",
      "20.200.245.247/32",
      "20.200.245.248/32",
      "20.201.28.144/32",
      "20.201.28.148/32",
      "20.201.28.149/32",
      "20.201.28.151/32",
      "20.201.28.152/32",
      "20.205.243.160/32",
      "20.205.243.164/32",
      "20.205.243.165/32",
      "20.205.243.166/32",
      "20.205.243.168/32",
      "20.207.73.82/32",
      "20.207.73.83/32",
      "20.207.73.85/32",
      "20.207.73.86/32",
      "20.207.73.88/32",
      "20.217.135.1/32",
      "20.233.83.145/32",
      "20.233.83.146/32",
      "20.233.83.147/32",
      "20.233.83.149/32",
      "20.233.83.150/32",
      "20.248.137.48/32",
      "20.248.137.49/32",
      "20.248.137.50/32",
      "20.248.137.52/32",
      "20.248.137.55/32",
      "20.26.156.215/32",
      "20.26.156.216/32",
      "20.26.156.211/32",
      "20.27.177.113/32",
      "20.27.177.114/32",
      "20.27.177.116/32",
      "20.27.177.117/32",
      "20.27.177.118/32",
      "20.29.134.17/32",
      "20.29.134.18/32",
      "20.29.134.19/32",
      "20.29.134.23/32",
      "20.29.134.24/32",
      "20.87.245.0/32",
      "20.87.245.1/32",
      "20.87.245.4/32",
      "20.87.245.6/32",
      "20.87.245.7/32",
      "4.208.26.196/32",
      "4.208.26.197/32",
      "4.208.26.198/32",
      "4.208.26.199/32",
      "4.208.26.200/32",
      "4.225.11.196/32",
      "4.237.22.32/32"
    ]
  }

  # Allow outbound to Azure Storage
  security_rule {
    name                       = "AllowStorageOutbound"
    priority                   = 230
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Storage"
  }

  # Deny all other outbound traffic
  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.main,
  azurerm_subnet.github_hosted_runners]
}

# Associate NSG with GitHub Runners Subnet
resource "azurerm_subnet_network_security_group_association" "github_runners" {
  subnet_id                 = azurerm_subnet.github_hosted_runners.id
  network_security_group_id = azurerm_network_security_group.github_runners_nsg.id

  depends_on = [
    azurerm_subnet.github_hosted_runners,
  azurerm_network_security_group.github_runners_nsg]
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
    name                 = "dns-group-storage-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
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
    name                 = "dns-group-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
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
    name                 = "dns-group-language"
    private_dns_zone_ids = [azurerm_private_dns_zone.cognitive.id]
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
    name                 = "dns-group-ai-services"
    private_dns_zone_ids = [azurerm_private_dns_zone.cognitive.id]
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
