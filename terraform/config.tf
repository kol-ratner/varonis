terraform {
  backend "azurerm" {
    resource_group_name  = "restaurant-recommender-rg"
    storage_account_name = "tfstaterestaurants"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
