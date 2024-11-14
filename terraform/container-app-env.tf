resource "azurerm_container_app_environment" "env" {
  name                       = "restaurant-recommender-env"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  infrastructure_subnet_id   = azurerm_subnet.priv_subnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "restaurant-recommender-logs"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
