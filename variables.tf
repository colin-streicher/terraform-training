variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type = list(string)
  default = ["10.10.0.0/16"]
}

variable "internal_subnet_space" {
  description = "Address space for internal subnet space"
  type = list(string)
  default = ["10.10.10.0/24"]
}

variable "tags" {
  type = map(string)
  description = "Tags"
}