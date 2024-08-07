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
