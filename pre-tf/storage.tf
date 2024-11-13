resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstaterestaurants"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.tfstate
  ]
}
