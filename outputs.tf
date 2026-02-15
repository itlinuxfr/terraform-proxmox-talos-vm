output "vm_id" {
  value       = proxmox_virtual_environment_vm.this.vm_id
  description = "The ID of the VM"
}

output "ipv4_addresses" {
  value       = flatten(proxmox_virtual_environment_vm.this.ipv4_addresses)
  description = "List of IPv4 addresses assigned to the VM"
}

output "mac_addresses" {
  value       = flatten(proxmox_virtual_environment_vm.this.mac_addresses)
  description = "List of MAC addresses assigned to the VM"
}
