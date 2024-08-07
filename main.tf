locals {
  l_tags = merge(var.tags, {client=var.client_name})
  vm_name = random_pet.pet-name.id
}

data "azurerm_subscription" "training" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = local.l_tags
}

resource "azurerm_ssh_public_key" "sshkey" {
  location            = azurerm_resource_group.rg.location
  name                = "${random_pet.pet-name.id}-sshkey"
  public_key          = file("~/.ssh/id_rsa.pub")
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "uai" {
  location            = azurerm_resource_group.rg.location
  name                = "${random_pet.pet-name.id}-uai"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "kv_certificate_user" {
  principal_id = azurerm_user_assigned_identity.uai.principal_id
#  role_definition_id = "db79e9a7-68ee-4b58-9aeb-b90e7c24fcba"
  role_definition_name = "Key Vault Certificate User"
  scope        = data.azurerm_subscription.training.id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  principal_id = azurerm_user_assigned_identity.uai.principal_id
#  role_definition_id = "4633458b-17de-408a-b874-0445c86b69e6"
  role_definition_name = "Key Vault Secrets User"
  scope        = data.azurerm_subscription.training.id
}

## Virtual Machine ==============
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                  = local.vm_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_A4_v2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = local.l_tags

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai.id]
  }

  os_disk {
    name                 = "OsDisk_1_${random_id.rnd.hex}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server-gen1"
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
#  depends_on = [azurerm_key_vault.akv]
#  lifecycle {
#    ignore_changes = [azure]
#  }
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
