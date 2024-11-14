resource "azurerm_container_app_environment" "env" {
  name                       = "restaurant-recommender-env"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  infrastructure_subnet_id   = azurerm_subnet.priv_subnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

resource "random_id" "random_id" {
  byte_length = 4
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "restaurant-recommender-logs"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_storage_account" "restaurants" {
  name                     = "restaurants${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_container_app_environment_storage" "postgres" {
  name                         = "postgres-storage"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = "postgres"
  share_name                   = "postgresql"
  access_mode                  = "ReadWrite"
  access_key                   = azurerm_storage_account.restaurants.primary_access_key
}

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
