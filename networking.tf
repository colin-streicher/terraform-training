
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
    security_rule {
    name                       = "HTTP"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "gw_nsg" {
  name                = "${random_pet.pet-name.id}-gw-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.l_tags

  security_rule {
    name                       = "HTTP"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "AllowMgmt"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "65200-65535"
    destination_port_range = "*"
    destination_address_prefix = "*"
    source_address_prefixes    = ["0.0.0.0/0"]
  }
}

resource "azurerm_public_ip" "alb-public-ip" {
  name                = "${random_pet.pet-name.id}-gw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_subnet" "subnet_internal" {
  name                 = "${random_pet.pet-name.id}-subnet"
  address_prefixes     = var.internal_subnet_space
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "bastionsubnet" {
  address_prefixes     = var.bastion_subnet
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "gw_subnet" {
  name = "${random_pet.pet-name.id}-gw-subnet"
  address_prefixes = var.gateway_subnet
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  network_security_group_id = azurerm_network_security_group.nsg.id
  subnet_id                 = azurerm_subnet.subnet_internal.id
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${random_pet.pet-name.id}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.l_tags
}

locals {
  gw_ip_configuration = "${random_pet.pet-name.id}-gwc"
  fe_ip_configuration = "${random_pet.pet-name.id}-fec"
  fe_port_name = "${random_pet.pet-name.id}-fep"
  be_address_pool = "${random_pet.pet-name.id}-bep"
  be_http_settings = "${random_pet.pet-name.id}-https"
  http_listener = "${random_pet.pet-name.id}-httpl"
  request_routing_rule = "${random_pet.pet-name.id}-rrr"

}
resource "azurerm_application_gateway" "gw" {
  location            = azurerm_resource_group.rg.location
  name                = "${random_pet.pet-name.id}-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = local.gw_ip_configuration
    subnet_id = azurerm_subnet.gw_subnet.id
  }

  frontend_ip_configuration {
    name = local.fe_ip_configuration
    public_ip_address_id = azurerm_public_ip.alb-public-ip.id
  }

  frontend_port {
    name = local.fe_port_name
    port = 80
  }

  backend_address_pool {
    name = local.be_address_pool
    ip_addresses = [azurerm_linux_virtual_machine.linux_vm.private_ip_address]
  }

  backend_http_settings {
    name                  = local.be_http_settings
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    frontend_ip_configuration_name = local.fe_ip_configuration
    frontend_port_name             = local.fe_port_name
    name                           = local.http_listener
    protocol                       = "Http"
  }

  request_routing_rule {
    http_listener_name = local.http_listener
    name               = local.request_routing_rule
    rule_type          = "Basic"
    priority = 9
    backend_address_pool_name = local.be_address_pool
    backend_http_settings_name = local.be_http_settings
  }
}

resource "azurerm_dns_a_record" "dns_record" {
  name = random_pet.pet-name.id
  zone_name = "training.motumdev.com"
  ttl = 300
  resource_group_name = "TrainingDNS"
  records = ["${azurerm_public_ip.alb-public-ip.ip_address}"]
}
