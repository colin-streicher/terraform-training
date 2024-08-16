data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  location            = azurerm_resource_group.rg.location
  name                = "${random_pet.pet-name.id}-kv"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
  enabled_for_deployment = true
  enable_rbac_authorization = true
}