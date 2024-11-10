output "github_actions_sp_client_id" {
  value = azuread_service_principal.github_actions.client_id
}

output "github_actions_sp_tenant_id" {
  value = azuread_service_principal.github_actions.application_tenant_id
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}
