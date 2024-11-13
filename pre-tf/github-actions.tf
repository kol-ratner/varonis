data "azurerm_subscription" "current" {}
data "azuread_client_config" "current" {}

resource "azuread_application" "github_actions" {
  display_name = "github-actions-terraform"
  owners       = [data.azuread_client_config.current.object_id]

  depends_on = [azurerm_resource_group.rg]
}

resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_role_assignment" "github_actions" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id

  depends_on = [azurerm_resource_group.rg]
}

resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-terraform-push"
  description    = "Terraform via github actions"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:kol-ratner/varonis:ref:refs/heads/main"

  depends_on = [azurerm_resource_group.rg]
}

resource "azuread_application_federated_identity_credential" "pull_request" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-terraform-pr"
  description    = "Terraform via github actions"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:kol-ratner/varonis:pull_request"

  depends_on = [azurerm_resource_group.rg]
}
