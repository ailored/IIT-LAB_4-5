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
