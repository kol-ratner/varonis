resource "azurerm_public_ip" "k3s_lb" {
  name                = "k3s-lb-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "k3s" {
  name                = "k3s-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "k3s-frontend"
    public_ip_address_id = azurerm_public_ip.k3s_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "k3s" {
  name            = "k3s-backend"
  loadbalancer_id = azurerm_lb.k3s.id
}

resource "azurerm_lb_rule" "k3s" {
  name                           = "k3s-api"
  loadbalancer_id                = azurerm_lb.k3s.id
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "k3s-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s.id]
  probe_id                       = azurerm_lb_probe.k3s.id
}

resource "azurerm_lb_probe" "k3s" {
  name            = "k3s-probe"
  loadbalancer_id = azurerm_lb.k3s.id
  protocol        = "Tcp"
  port            = 6443
}

resource "azurerm_network_interface_backend_address_pool_association" "k3s" {
  network_interface_id    = azurerm_network_interface.k3s_node.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.k3s.id
}
