
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