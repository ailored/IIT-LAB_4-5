resource "azurerm_resource_group" "resourcegroup" {
  name     = "iit-lab6-group"
  location = "West Europe"
}

resource "azurerm_public_ip" "publicip" {
  name                = "iit-lab6-ip"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
}

resource "tls_private_key" "iitlab6_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
