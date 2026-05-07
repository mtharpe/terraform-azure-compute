locals {
  parts = split(",", lookup(var.standard_os, var.vm_os_simple, ",,"))
}

output "calculated_value_os_publisher" {
  description = "Resolved publisher for vm_os_simple, or empty string when not in catalog."
  value       = element(local.parts, 0)
}

output "calculated_value_os_offer" {
  description = "Resolved offer for vm_os_simple, or empty string."
  value       = element(local.parts, 1)
}

output "calculated_value_os_sku" {
  description = "Resolved SKU for vm_os_simple, or empty string."
  value       = element(local.parts, 2)
}

output "calculated_remote_port" {
  description = "Default remote management port: 3389 for Windows, 22 otherwise."
  value       = element(local.parts, 0) == "MicrosoftWindowsServer" ? "3389" : "22"
}
