# Add output to get the public IP
output "public_ip" {
  value = azurerm_public_ip.k3s_lb.ip_address
}
