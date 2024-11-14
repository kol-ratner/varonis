resource "azurerm_container_app" "restaurant_recommender" {
  name                         = "restaurant-recommender"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "restaurant-recommender"
      image  = "ghcr.io/kol-ratner/varonis/restaurant-recommender:20241108065014-02b66fa"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_HOST"
        value = "localhost"
      }
      env {
        name  = "DB_PORT"
        value = "5432"
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

    container {
      name   = "postgres"
      image  = "postgres:14"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "POSTGRES_DB"
        value = "restaurant_db"
      }
      env {
        name  = "POSTGRES_USER"
        value = "restaurants_user"
      }
      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "db-password"
      }

      volume_mounts {
        name = "postgres-data"
        path = "/var/lib/postgresql/data"
      }

      liveness_probe {
        initial_delay = 15
        port          = 5432
        transport     = "TCP"
      }
    }

    volume {
      name         = "postgres-data"
      storage_name = azurerm_container_app_environment_storage.postgres.name
      storage_type = "AzureFile"
    }
  }

  secret {
    name  = "db-password"
    value = azurerm_key_vault_secret.restaurants_user_password.value
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
