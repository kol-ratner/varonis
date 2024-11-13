resource "azurerm_postgresql_flexible_server" "db" {
  name                = "restaurant-db"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  version             = "14"

  storage_mb = 32768

  administrator_login    = "psqladmin"
  administrator_password = azurerm_key_vault_secret.db_admin_password.value

  zone = "1"

  #   private_dns_zone_id = azurerm_private_dns_zone.priv.id
  delegated_subnet_id = azurerm_subnet.priv_subnet.id
}

resource "azurerm_postgresql_flexible_server_configuration" "restaurants_user" {
  name      = "restaurants_user"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "CREATE USER restaurants_user WITH PASSWORD '${azurerm_key_vault_secret.restaurants_user_password.value}'; GRANT CONNECT ON DATABASE restaurant_db TO restaurants_user; GRANT USAGE ON SCHEMA public TO restaurants_user; GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO restaurants_user;"
}

# creating the psql database
resource "azurerm_postgresql_flexible_server_database" "restaurant_db" {
  name      = "restaurant_db"
  server_id = azurerm_postgresql_flexible_server.db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_app" {
#   name             = "allow-app"
#   server_id        = azurerm_postgresql_flexible_server.db.id
#   start_ip_address = data.azurerm_container_app.restaurant_recommender.outbound_ip_addresses[0]
#   end_ip_address   = data.azurerm_container_app.restaurant_recommender.outbound_ip_addresses[0]
# }
