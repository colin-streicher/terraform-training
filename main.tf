locals {
  l_tags = merge(var.tags, {})
}

resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.resource_group_location
}

# Generate random text for a unique storage account name
resource "random_id" "rnd" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 4
}

## Virtual Machine ==============
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                  = "myvirtualmachine"
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_D2as_v4"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  tags = local.l_tags

  os_disk {
    name                 = "OsDisk_1_${random_id.rnd.hex}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "mycomputername"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "my-virtual-machine-ip"
  allocation_method   = "Static"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  tags                = local.l_tags
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  name                = "my-nsg"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  tags                = local.l_tags

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  tags                = local.l_tags

  ip_configuration {
    name                          = "nic_ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg-group-assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "subnet_internal" {
  name                 = "internal"
  address_prefixes     = var.internal_subnet_space
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name   = var.resource_group_name
}
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  address_space       = var.vnet_address_space
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  tags                = local.l_tags
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "private_key_pem" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}