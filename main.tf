locals {
  l_tags = merge(var.tags, {})
  vm_name = random_pet.pet-name.id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_ssh_public_key" "sshkey" {
  location            = azurerm_resource_group.rg.location
  name                = "${random_pet.pet-name.id}-sshkey"
  public_key          = file("~/.ssh/id_rsa.pub")
  resource_group_name = azurerm_resource_group.rg.name
}

# Generate random text for a unique storage account name
resource "random_id" "rnd" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 4
}

resource "random_pet" "pet-name" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }
}

## Virtual Machine ==============
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                  = local.vm_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_D2as_v4"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = local.l_tags

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

  computer_name                   = local.vm_name
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.sshkey.public_key
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${local.vm_name}-ip"
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.l_tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${random_pet.pet-name.id}-security-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
  name                = "${local.vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.l_tags

  ip_configuration {
    name                          = "${local.vm_name}-ip-config"
    subnet_id                     = azurerm_subnet.subnet_internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg-group-assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "subnet_internal" {
  name                 = "${random_pet.pet-name.id}-subnet"
  address_prefixes     = var.internal_subnet_space
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${random_pet.pet-name.id}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.l_tags
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

