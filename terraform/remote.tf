data "azurerm_resource_group" "rg" {
  name = "restaurant-recommender-rg"
}

data "azurerm_client_config" "current" {}
