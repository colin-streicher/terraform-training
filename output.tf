output "connection-details" {
  value = {
    username=azurerm_linux_virtual_machine.linux_vm.admin_username
    public_ip=azurerm_public_ip.public_ip.ip_address
  }
}

output "load-balancer-endpoints" {
  value = {
    public_ip=azurerm_public_ip.alb-public-ip.ip_address
  }
}