output "private_key_pem" {
  value     = nonsensitive(tls_private_key.ssh.private_key_pem)
}

output "vm" {
  value = {
    config = {
      username=azurerm_linux_virtual_machine.linux_vm.admin_username
      public_ip=azurerm_linux_virtual_machine.linux_vm.public_ip_address
      computer_name=azurerm_linux_virtual_machine.linux_vm.name
    }
  }
}