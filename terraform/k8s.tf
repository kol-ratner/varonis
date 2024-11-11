
resource "azurerm_network_interface" "k3s_node" {
  name                = "k3s-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.priv_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "k3s" {
  network_interface_id      = azurerm_network_interface.k3s_node.id
  network_security_group_id = azurerm_network_security_group.priv_nsg.id
}

# it seems like azure forces me to attach an ssh key by default
# but keep in mind that currently our nsg doesnt allow ssh traffic
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "k3s" {
  name                = "k3s"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  network_interface_ids = [
    azurerm_network_interface.k3s_node.id
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
  admin_username = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

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
