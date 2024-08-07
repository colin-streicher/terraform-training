output "vm" {
  value = {
    config = {
      username=azurerm_linux_virtual_machine.linux_vm.admin_username
      public_ip=azurerm_linux_virtual_machine.linux_vm.public_ip_address
      computer_name=azurerm_linux_virtual_machine.linux_vm.name
    }
  }
}