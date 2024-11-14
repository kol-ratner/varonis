resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "postgres" {
  name                     = "postgresdata${random_string.storage_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "postgres" {
  name                 = "postgresql"
  storage_account_name = azurerm_storage_account.postgres.name
  quota                = 50
}


resource "azurerm_container_app_environment_storage" "postgres" {
  name                         = "postgres-storage"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.postgres.name
  share_name                   = azurerm_storage_share.postgres.name
  access_key                   = azurerm_storage_account.postgres.primary_access_key
  access_mode                  = "ReadWrite"
}
