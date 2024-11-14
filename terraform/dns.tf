resource "azurerm_private_dns_zone" "db" {
  name                = "restaurant.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "db" {
  name                  = "restaurant-db-link"
  private_dns_zone_name = azurerm_private_dns_zone.db.name
  resource_group_name   = data.azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
