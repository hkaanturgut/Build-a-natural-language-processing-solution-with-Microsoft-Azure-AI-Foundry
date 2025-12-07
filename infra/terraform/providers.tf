# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"

  required_providers {

    azapi = {
      source  = "azure/azapi"
      version = "~>1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.4"
    }
  }
}