resource "azurerm_container_app_environment" "env" {
  name                     = "restaurant-recommender-env"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  infrastructure_subnet_id = azurerm_subnet.app_subnet.id
}

resource "azurerm_container_app" "app" {
  name                         = "restaurant-recommender"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      name   = "restaurant-recommender"
      image  = "ghcr.io/${var.github_repo}/restaurant-recommender:latest"
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.db.fqdn
      }
      env {
        name  = "DB_NAME"
        value = "restaurant_db"
      }
      env {
        name  = "DB_USER"
        value = azurerm_postgresql_flexible_server.db.administrator_login
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
    }
  }
}
