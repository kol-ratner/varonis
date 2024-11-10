resource "azurerm_public_ip" "k3s" {
  name                = "k3s-ip"
  location            = data.azurerm_resource_group.rg.name
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

resource "azurerm_linux_virtual_machine" "k3s" {
  name                = "k3s"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.k3s.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
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

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "k3s-ssh-key.pem"
  file_permission = "0600"
}
