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
  validation {
    condition     = contains(["q35", "i440fx"], var.vm_machine_type)
    error_message = "Machine type must be either q35 or i440fx."
  }
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
  validation {
    condition     = contains(["virtio-scsi-pci", "virtio-scsi-single"], var.vm_scsi_hardware)
    error_message = "SCSI hardware must be virtio-scsi-pci or virtio-scsi-single."
  }
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
  validation {
    condition     = var.vm_sockets >= 1
    error_message = "Sockets must be at least 1."
  }
}

variable "vm_cores" {
  type        = number
  default     = 2
  description = "Number of CPU cores per socket"
  validation {
    condition     = var.vm_cores >= 1
    error_message = "Cores must be at least 1."
  }
}

variable "vm_memory" {
  type        = number
  default     = 2048
  description = "Memory in MiB"
  validation {
    condition     = var.vm_memory >= 512
    error_message = "Memory must be at least 512 MiB."
  }
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
  validation {
    condition = alltrue([
      for net in var.vm_network : contains(["virtio", "e1000", "vmxnet3", "rtl8139"], net.model)
    ])
    error_message = "Network model must be one of: virtio, e1000, vmxnet3, rtl8139."
  }
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
  validation {
    condition = alltrue([
      for disk in var.vm_disks : can(regex("^(scsi|virtio|sata|ide)\\d+$", disk.interface))
    ])
    error_message = "Disk interface must be one of: scsiN, virtioN, sataN, ideN (e.g., scsi0)."
  }
  validation {
    condition = alltrue([
      for disk in var.vm_disks : contains(["raw", "qcow2", "vmdk"], disk.format)
    ])
    error_message = "Disk format must be one of: raw, qcow2, vmdk."
  }
  validation {
    condition = alltrue([
      for disk in var.vm_disks : disk.size_gb > 0
    ])
    error_message = "Disk size must be greater than 0 GB."
  }
}

# Cloud-Init for Static IP bootstrapping (Talos can use this or kernel args)
variable "vm_cloudinit_interface" {
  type        = string
  description = "Interface for Cloud-Init drive (e.g., scsi30, ide3)"
  default     = "scsi30"
}

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
