variable "resource_group_name" {
  type    = string
  default = "colin-rg"
}

variable "resource_group_location" {
  type    = string
  default = "eastus"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "internal_subnet_space" {
  description = "Address space for internal subnet space"
  type        = list(string)
  default     = ["10.10.10.0/24"]
}

variable "gateway_subnet" {
  description = "Address space for gateways"
  type = list(string)
  default = ["10.10.11.0/24"]
}

variable "bastion_subnet" {
  description = "Subnet for bastion host"
  type = list(string)
  default = ["10.10.12.0/24"]
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}

variable "client_name" {
  default = "A new Client"
}