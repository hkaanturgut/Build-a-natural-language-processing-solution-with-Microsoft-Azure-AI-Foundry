# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"

  required_providers {

    azapi = {
      source  = "Azure/azapi"
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

  backend "azurerm" {
    resource_group_name  = "rg-cc-terraform"
    storage_account_name = "stccterraformstates01"
    container_name       = "qat"
    key                  = "terraform.tfstate"
  }
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}



# Get current client configuration
data "azurerm_client_config" "current" {}