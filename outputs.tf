output "vm_id" {
  description = "Proxmox VM ID."
  type        = number
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name, which is also the hostname Talos takes from cloud-init."
  type        = string
  value       = proxmox_virtual_environment_vm.this.name
}

output "node_name" {
  description = "Name of the Proxmox node that runs the VM."
  type        = string
  value       = proxmox_virtual_environment_vm.this.node_name
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by the QEMU guest agent. Empty until the guest agent answers."
  type        = list(string)
  value       = flatten(proxmox_virtual_environment_vm.this.ipv4_addresses)
}

output "mac_addresses" {
  description = "MAC addresses of the network devices."
  type        = list(string)
  value       = flatten(proxmox_virtual_environment_vm.this.mac_addresses)
}
