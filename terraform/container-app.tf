resource "azurerm_container_app_environment" "env" {
  name                     = "restaurant-recommender-env"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  infrastructure_subnet_id = azurerm_subnet.priv_subnet.id
}

resource "azurerm_container_app" "restaurant_recommender" {
  name                         = "restaurant-recommender"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

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
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.restaurant_db.name
      }
      env {
        name  = "DB_USER"
        value = "restaurants_user"
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  secret {
    name  = "db-password"
    value = azurerm_key_vault_secret.restaurants_user_password.value
  }
}
