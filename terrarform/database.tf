resource "random_password" "db_admin" {
  length  = 20
  special = true
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                = "restaurant-db"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  version             = "14"

  storage_mb = 32768

  administrator_login    = "psqladmin"
  administrator_password = random_password.db_admin.result

  zone = "1"

  private_dns_zone_id = azurerm_private_dns_zone.db.id
  delegated_subnet_id = azurerm_subnet.db_subnet.id
}

# creating the psql database
resource "azurerm_postgresql_flexible_server_database" "restaurant_db" {
  name      = "restaurant_db"
  server_id = azurerm_postgresql_flexible_server.db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_app" {
  name             = "allow-app"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = azurerm_container_app.restaurant_recommender.outbound_ip_addresses[0]
  end_ip_address   = azurerm_container_app.restaurant_recommender.outbound_ip_addresses[0]
}

resource "random_password" "restaurants_user_password" {
  length  = 20
  special = true
}

resource "azurerm_postgresql_flexible_server_configuration" "restaurants_user" {
  name      = "restaurants_user"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "CREATE USER restaurants_user WITH PASSWORD '${random_password.restaurants_user_password.result}'; GRANT CONNECT ON DATABASE restaurant_db TO restaurants_user; GRANT USAGE ON SCHEMA public TO restaurants_user; GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO restaurants_user;"
}

