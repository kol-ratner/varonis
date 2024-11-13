resource "azurerm_key_vault" "kv" {
  name                = "restaurant-recommender-kv"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "random_password" "db_admin" {
  length  = 20
  special = true
}

resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "db-admin-password"
  value        = random_password.db_admin.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "random_password" "restaurants_user_password" {
  length  = 20
  special = true
}

resource "azurerm_key_vault_secret" "restaurants_user_password" {
  name         = "restaurants-user-password"
  value        = random_password.restaurants_user_password.result
  key_vault_id = azurerm_key_vault.kv.id
}
