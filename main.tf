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

data "template_cloudinit_config" "craftcms_config" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = "packages: ['php', 'php-xml', 'composer', 'php-mysql', 'npm', 'nginx', 'python3-pip', 'python3-venv', 'mysql-server', 'mysql-client', 'php-bcmath', 'php-fpm']"
  }

  part {
    content_type = "text/x-shellscript"
    content = "sudo apt remove apache2 --assume-yes"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                  = local.vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  custom_data = data.template_cloudinit_config.craftcms_config.rendered
  tags                  = local.l_tags
  instances = 1
  source_image_id = "/subscriptions/d2dbb490-c354-494d-9492-250cbfd793fc/resourceGroups/MotumB2BImage/providers/Microsoft.Compute/images/craftcms_mysql_image"
  

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.sshkey.public_key
  }
  sku = "Standard_A1_v2"
  network_interface {
      name                = "${local.vm_name}-nic"
      primary = true
    ip_configuration {
      primary = true
      name                          = "${local.vm_name}-ip-config"
      subnet_id                     = azurerm_subnet.subnet_internal.id
      application_gateway_backend_address_pool_ids = [for name, value in azurerm_application_gateway.gw.backend_address_pool : value.id]
    }
  }
}
# ## Virtual Machine ==============
# resource "azurerm_linux_virtual_machine" "linux_vm" {
#   name                  = local.vm_name
#   network_interface_ids = [azurerm_network_interface.nic.id]
#   size                  = "Standard_A1_v2"
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   custom_data = data.template_cloudinit_config.craftcms_config.rendered
#   tags                  = local.l_tags
#   source_image_id = "/subscriptions/d2dbb490-c354-494d-9492-250cbfd793fc/resourceGroups/MotumB2BImage/providers/Microsoft.Compute/images/craftcms_mysql_image"
  

#   identity {
#     type = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.uai.id]
#   }

#   os_disk {
#     name                 = "OsDisk_1_${random_id.rnd.hex}"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   computer_name                   = local.vm_name
#   admin_username                  = "azureuser"
#   disable_password_authentication = true

#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = azurerm_ssh_public_key.sshkey.public_key
#   }
# }

# # Create network interface
# resource "azurerm_network_interface" "nic" {
#   name                = "${local.vm_name}-nic"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tags                = local.l_tags

#   ip_configuration {
#     name                          = "${local.vm_name}-ip-config"
#     subnet_id                     = azurerm_subnet.subnet_internal.id
#     public_ip_address_id = azurerm_public_ip.public_ip.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }
