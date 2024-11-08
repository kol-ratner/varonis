resource "azurerm_key_vault" "kv" {
  name                = "restaurant-${local.environment}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = azurerm_postgresql_flexible_server.db.administrator_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                = "restaurant-db"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  version             = "14"

  storage_mb = 32768

  administrator_login    = "psqladmin"
  administrator_password = random_password.db_password.result

  zone = "1"

  private_dns_zone_id = azurerm_private_dns_zone.db.id
  delegated_subnet_id = azurerm_subnet.db_subnet.id
}
