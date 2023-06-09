variable "ARM_SUBSCRIPTION_ID" {
  type = string
}
variable "ARM_CLIENT_ID" {
  type = string
}
variable "ARM_CLIENT_SECRET" {
  type = string
}
variable "ARM_TENANT_ID" {
  type = string
}

terraform {
  backend "remote" {
    organization = "IIT-LAB6-IA03-TEAM5"

    workspaces {
      name = "lab6-terraform-gh-actions"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}

  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID
}

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
resource "azurerm_virtual_network" "virtualnetwork" {
  name                = "iit-lab6-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "iit-lab6-subnet"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "netsecuritygroup" {
  name                = "iit-lab6-nsg"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "networkinterface" {
  name                = "iit-lab6-nic"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "iit-lab6-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "networkassociation" {
  network_interface_id      = azurerm_network_interface.networkinterface.id
  network_security_group_id = azurerm_network_security_group.netsecuritygroup.id
}

resource "azurerm_linux_virtual_machine" "linuxvm" {
  name                            = "iit-lab6-vm"
  location                        = azurerm_resource_group.resourcegroup.location
  resource_group_name             = azurerm_resource_group.resourcegroup.name
  network_interface_ids           = [azurerm_network_interface.networkinterface.id]
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  computer_name                   = "terraformvm"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.iitlab6_ssh.public_key_openssh
  }

  os_disk {
    name                 = "iit-lab6-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  user_data = filebase64("${path.module}/terraform-lab6/scripts/vm-init.sh")
}

output "resource_group_name" {
  value = azurerm_resource_group.resourcegroup.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.linuxvm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.iitlab6_ssh.private_key_pem
  sensitive = true
}
