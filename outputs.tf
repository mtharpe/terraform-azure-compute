output "vm_ids" {
  description = "IDs of the virtual machines created"
  value       = local.vm_ids
}

output "vm_names" {
  description = "Names of the virtual machines created"
  value       = local.is_windows ? azurerm_windows_virtual_machine.vm[*].name : azurerm_linux_virtual_machine.vm[*].name
}

output "network_security_group_id" {
  description = "ID of the network security group provisioned"
  value       = azurerm_network_security_group.vm.id
}

output "network_security_group_name" {
  description = "Name of the network security group provisioned"
  value       = azurerm_network_security_group.vm.name
}

output "network_interface_ids" {
  description = "IDs of the VM NICs provisioned"
  value       = azurerm_network_interface.vm[*].id
}

output "network_interface_private_ip" {
  description = "Private IP addresses of the VM NICs"
  value       = azurerm_network_interface.vm[*].private_ip_address
}

output "public_ip_id" {
  description = "IDs of the public IP addresses provisioned"
  value       = azurerm_public_ip.vm[*].id
}

output "public_ip_address" {
  description = "Allocated public IP addresses"
  value       = azurerm_public_ip.vm[*].ip_address
}

output "public_ip_dns_name" {
  description = "FQDNs of the provisioned public IPs"
  value       = azurerm_public_ip.vm[*].fqdn
}

output "availability_set_id" {
  description = "ID of the availability set, if one was created"
  value       = local.use_avset ? azurerm_availability_set.vm[0].id : null
}

output "data_disk_ids" {
  description = "IDs of the managed data disks, keyed by \"<vm_index>-<lun>\""
  value       = { for k, v in azurerm_managed_disk.vm : k => v.id }
}
