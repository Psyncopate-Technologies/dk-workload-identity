output "vm_id" {
  description = "VM resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "VM name (for `az vm run-command`)."
  value       = azurerm_linux_virtual_machine.this.name
}

output "resource_group_name" {
  description = "RG hosting the VM (for `az vm run-command`)."
  value       = azurerm_linux_virtual_machine.this.resource_group_name
}

output "private_ip_address" {
  description = "VM NIC private IP."
  value       = azurerm_network_interface.this.private_ip_address
}
