resource "azurerm_public_ip" "k3s" {
  name                = "k3s-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"

}
resource "azurerm_network_interface" "k3s" {
  name                = "k3s-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.priv_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.k3s.id
  }
}

resource "azurerm_network_interface_security_group_association" "k3s" {
  network_interface_id      = azurerm_network_interface.k3s.id
  network_security_group_id = azurerm_network_security_group.priv_nsg.id
}

resource "azurerm_storage_account" "k3s" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "k3s" {
  name                = "k3s"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  network_interface_ids = [
    azurerm_network_interface.k3s.id
  ]
  size = "Standard_B2s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = "admin"

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.k3s.primary_blob_endpoint
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | sh -
    # Get kubeconfig for remote access
    sudo cat /etc/rancher/k3s/k3s.yaml > /home/adminuser/kubeconfig.yaml
    sudo chown adminuser:adminuser /home/adminuser/kubeconfig.yaml
  EOF
  )
}
