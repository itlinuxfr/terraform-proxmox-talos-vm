variable "proxmox_node" {
  type        = string
  description = "Target Proxmox Node Name"
  validation {
    condition     = length(var.proxmox_node) > 0
    error_message = "Proxmox node name must not be empty."
  }
}

variable "vm_name" {
  type        = string
  description = "Name of the VM (will also be used as hostname)"
  validation {
    condition     = length(var.vm_name) > 0
    error_message = "VM name must not be empty."
  }
}

variable "vm_description" {
  type        = string
  default     = "Managed by Terraform"
  description = "Description of the VM"
}

variable "vm_tags" {
  type        = list(string)
  default     = []
  description = "List of tags to apply to the VM"
}

variable "vm_onboot" {
  type        = bool
  default     = true
  description = "Start VM on node boot"
}

variable "vm_start" {
  type        = bool
  default     = true
  description = "Start VM after creation"
}

variable "vm_machine_type" {
  type        = string
  default     = "q35"
  description = "Machine type (q35 recommended for Talos)"
}

variable "vm_bios" {
  type        = string
  default     = "seabios"
  description = "BIOS type (seabios or ovmf)"
  validation {
    condition     = contains(["seabios", "ovmf"], var.vm_bios)
    error_message = "BIOS must be either seabios or ovmf."
  }
}

variable "vm_scsi_hardware" {
  type        = string
  default     = "virtio-scsi-pci"
  description = "SCSI controller model (virtio-scsi-pci recommended for Talos)"
}

variable "vm_cpu_type" {
  type        = string
  default     = "host"
  description = "CPU type (host recommended for performance)"
}

variable "vm_sockets" {
  type        = number
  default     = 1
  description = "Number of CPU sockets"
}

variable "vm_cores" {
  type        = number
  default     = 2
  description = "Number of CPU cores per socket"
}

variable "vm_memory" {
  type        = number
  default     = 2048
  description = "Memory in MiB"
}

variable "vm_iso" {
  type        = string
  description = "ISO File ID to mount (e.g., local:iso/talos.iso)"
}

variable "vm_guest_agent" {
  type        = bool
  default     = true
  description = "Enable QEMU Guest Agent"
}

variable "vm_network" {
  description = "List of network interfaces"
  type = list(object({
    bridge   = string
    model    = optional(string, "virtio")
    mac_addr = optional(string)
    tag      = optional(number)
    firewall = optional(bool, false)
  }))
  default = [
    {
      bridge = "vmbr0"
      model  = "virtio"
    }
  ]
}

variable "vm_disks" {
  description = "List of disks"
  type = list(object({
    datastore_id = string
    interface    = string # scsi, virtio, sata
    size_gb      = number
    format       = optional(string, "raw")
    ssd          = optional(bool, true) # Recommended for etcd
    discard      = optional(bool, true)
    iothread     = optional(bool, true)
  }))
  validation {
    condition     = length(var.vm_disks) > 0
    error_message = "At least one disk must be defined."
  }
}

# Cloud-Init for Static IP bootstrapping (Talos can use this or kernel args)
variable "vm_cloudinit_datastore" {
  type        = string
  description = "Datastore for Cloud-Init drive"
  default     = null
}

variable "vm_cloudinit_ip_config" {
  description = "Cloud-Init IP Configuration (list of configs matching network interfaces)"
  type = list(object({
    ipv4 = object({
      address = string
      gateway = optional(string)
    })
  }))
  default = []
}
