resource "random_id" "random_id" {
  byte_length = 8
}

resource "azurerm_storage_account" "k3s" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
