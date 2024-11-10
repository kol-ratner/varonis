data "azurerm_subscription" "current" {}
data "azuread_client_config" "current" {}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstaterestaurantrec"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}


resource "azuread_application" "github_actions" {
  display_name = "github-actions-terraform"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_registration" "github_actions" {
  display_name = "github-actions-terraform"
}

resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "github_actions" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application_registration.github_actions.id
  display_name   = "github-actions-terraform"
  description    = "Terraform via github actions"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:kol-ratner/varonis:*"
}
