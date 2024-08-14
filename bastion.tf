
resource "azurerm_public_ip" "public_ip" {
  name                = "${random_pet.pet-name.id}-bastion-public-ip"
  allocation_method   = "Static"
  sku = "Standard"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.l_tags
}
#
#resource "azurerm_bastion_host" "bastion_host" {
#  name                = "${random_pet.pet-name.id}-bastion"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#
#  ip_configuration {
#    name                 = "${random_pet.pet-name.id}-bastion-ip-conf"
#    subnet_id            = azurerm_subnet.bastionsubnet.id
#    public_ip_address_id = azurerm_public_ip.public_ip.id
#  }
#}