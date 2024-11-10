resource "azurerm_virtual_network" "vnet" {
  name                = "restaurant-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "pub_subnet" {
  name                 = "pub-subnet-${azurerm_resource_group.rg.location}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "pub_nsg" {
  name                = "pub-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pub" {
  subnet_id                 = azurerm_subnet.pub_subnet.id
  network_security_group_id = azurerm_network_security_group.pub_nsg.id
}

resource "azurerm_subnet" "priv_subnet" {
  name                 = "priv-subnet-${azurerm_resource_group.rg.location}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "priv_nsg" {
  name                = "priv-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-priv-from-pub"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.pub_subnet.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.priv_subnet.address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "priv" {
  subnet_id                 = azurerm_subnet.priv_subnet.id
  network_security_group_id = azurerm_network_security_group.priv_nsg.id
}
