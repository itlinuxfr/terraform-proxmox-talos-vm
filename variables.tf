variable "node_name" {
  description = "Name of the Proxmox node that runs the VM."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.node_name) != ""
    error_message = "The node name must not be empty."
  }
}

variable "name" {
  description = "VM name. Proxmox gives it to cloud-init, and Talos uses it as the hostname: lowercase letters, digits and hyphens."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "The name must be a valid hostname label: lowercase letters, digits and hyphens, 63 characters at most, no hyphen at the start or the end."
  }
}

variable "vm_id" {
  description = "Proxmox VM ID. Null lets Proxmox pick the next free ID. Set it when permissions or backups are bound to the ID."
  type        = number
  default     = null

  validation {
    condition     = var.vm_id == null ? true : (var.vm_id >= 100 && var.vm_id <= 999999999 && floor(var.vm_id) == var.vm_id)
    error_message = "The VM ID must be an integer between 100 and 999999999."
  }
}

variable "description" {
  description = "VM description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Proxmox tags of the VM."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "pool_id" {
  description = "ID of the Proxmox resource pool that holds the VM. Null puts no pool. Required when the API token only has rights on a pool."
  type        = string
  default     = null
}

variable "started" {
  description = "Start the VM after creation."
  type        = bool
  default     = true
  nullable    = false
}

variable "on_boot" {
  description = "Start the VM when the Proxmox node boots."
  type        = bool
  default     = true
  nullable    = false
}

variable "stop_on_destroy" {
  description = "Power the VM off on destroy instead of asking the guest to shut down. A Talos node is rebuilt from its configuration, so waiting for a graceful shutdown gains nothing."
  type        = bool
  default     = true
  nullable    = false
}

variable "machine" {
  description = "Machine type: q35 (PCIe, needed for UEFI and TPM) or pc (i440fx)."
  type        = string
  default     = "q35"
  nullable    = false

  validation {
    condition     = contains(["q35", "pc"], var.machine)
    error_message = "The machine type must be q35 or pc."
  }
}

variable "firmware" {
  description = <<-EOT
    Firmware.
    - bios: seabios (legacy BIOS) or ovmf (UEFI). ovmf adds an EFI disk, which SecureBoot needs.
    - efi_datastore_id: datastore of the EFI disk. Null uses the datastore of the first disk.
    - pre_enrolled_keys: boot with the Microsoft keys already enrolled. Keep false for Talos SecureBoot: the Talos image enrolls its own keys in setup mode.
  EOT
  type = object({
    bios              = optional(string, "seabios")
    efi_datastore_id  = optional(string)
    pre_enrolled_keys = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["seabios", "ovmf"], var.firmware.bios)
    error_message = "firmware.bios must be seabios or ovmf."
  }
}

variable "tpm" {
  description = "Add a virtual TPM. Null adds none. Talos can seal disk encryption keys in the TPM, which needs SecureBoot (firmware.bios = ovmf). datastore_id null uses the datastore of the first disk."
  type = object({
    datastore_id = optional(string)
    version      = optional(string, "v2.0")
  })
  default = null

  validation {
    condition     = var.tpm == null ? true : contains(["v1.2", "v2.0"], var.tpm.version)
    error_message = "tpm.version must be v1.2 or v2.0."
  }
}

variable "cpu" {
  description = "CPU. type host gives the guest the real CPU features (Talos needs x86-64-v2)."
  type = object({
    type    = optional(string, "host")
    cores   = optional(number, 2)
    sockets = optional(number, 1)
    numa    = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.cpu.cores >= 1 && var.cpu.sockets >= 1 && floor(var.cpu.cores) == var.cpu.cores && floor(var.cpu.sockets) == var.cpu.sockets
    error_message = "cpu.cores and cpu.sockets must be integers of at least 1."
  }
}

variable "memory" {
  description = "Memory in MiB. floating_mb is the balloon minimum: keep 0 to disable ballooning, because Talos does not handle memory hotplug."
  type = object({
    dedicated_mb = optional(number, 2048)
    floating_mb  = optional(number, 0)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.memory.dedicated_mb >= 512 && var.memory.floating_mb >= 0 && var.memory.floating_mb <= var.memory.dedicated_mb
    error_message = "memory.dedicated_mb must be at least 512 and memory.floating_mb must be between 0 and dedicated_mb."
  }
}

variable "scsi_hardware" {
  description = "SCSI controller. virtio-scsi-pci is the Talos recommendation for Proxmox (virtio-scsi-single blocks the bootstrap, see siderolabs/talos#11173). Disk iothread needs virtio-scsi-single."
  type        = string
  default     = "virtio-scsi-pci"
  nullable    = false

  validation {
    condition     = contains(["lsi", "lsi53c810", "virtio-scsi-pci", "virtio-scsi-single", "megasas", "pvscsi"], var.scsi_hardware)
    error_message = "scsi_hardware must be lsi, lsi53c810, virtio-scsi-pci, virtio-scsi-single, megasas or pvscsi."
  }
}

variable "operating_system_type" {
  description = "Guest operating system type for Proxmox tuning. l26 is Linux 2.6 and later."
  type        = string
  default     = "l26"
  nullable    = false
}

variable "agent" {
  description = "QEMU guest agent. Talos needs the siderolabs/qemu-guest-agent extension in its image for the VM to report its IP addresses."
  type = object({
    enabled = optional(bool, true)
    trim    = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "disks" {
  description = <<-EOT
    Disks, keyed by Proxmox interface (scsi0, virtio0, sata0, ide0...). The first key in alphabetical order is the boot disk.
    - size_gb: disk size in GiB. With import_from it must be at least the size of the image.
    - import_from: ID of a disk image to import, for example the id output of terraform-proxmox-download-file with the import content type. Used at creation only.
    - discard: pass trim requests to the storage. iothread needs scsi_hardware = virtio-scsi-single.
  EOT
  type = map(object({
    datastore_id = string
    size_gb      = number
    file_format  = optional(string, "raw")
    ssd          = optional(bool, true)
    discard      = optional(bool, true)
    iothread     = optional(bool, false)
    import_from  = optional(string)
  }))
  nullable = false

  validation {
    condition     = length(var.disks) >= 1
    error_message = "At least one disk is required."
  }

  validation {
    condition     = alltrue([for interface in keys(var.disks) : can(regex("^(scsi|virtio|sata|ide)[0-9]+$", interface))])
    error_message = "Disk keys must be Proxmox interfaces such as scsi0, virtio0, sata0 or ide0."
  }

  validation {
    condition     = alltrue([for disk in values(var.disks) : disk.size_gb >= 1 && floor(disk.size_gb) == disk.size_gb])
    error_message = "Each disk size_gb must be an integer of at least 1."
  }
}

variable "cdrom" {
  description = "CD-ROM with a boot image, for example the id output of terraform-proxmox-download-file. Null adds none. The default interface ide3 leaves ide2 to the cloud-init drive."
  type = object({
    file_id   = string
    interface = optional(string, "ide3")
  })
  default = null

  validation {
    condition     = var.cdrom == null ? true : can(regex("^(ide|sata)[0-9]+$", var.cdrom.interface))
    error_message = "cdrom.interface must be an ide or sata interface such as ide3."
  }

  validation {
    condition     = var.cdrom == null ? true : !contains(keys(var.disks), var.cdrom.interface)
    error_message = "cdrom.interface is already used by a disk."
  }

  validation {
    condition     = var.cdrom == null || var.cloud_init == null ? true : var.cdrom.interface != var.cloud_init.interface
    error_message = "cdrom.interface is already used by the cloud-init drive."
  }
}

variable "boot_order" {
  description = "Boot order, for example [\"scsi0\", \"ide3\"]. Null boots from the first disk, then from the CD-ROM: the empty disk is skipped on the first boot, so the image takes over, and the installed system boots afterwards."
  type        = list(string)
  default     = null

  validation {
    condition     = var.boot_order == null ? true : alltrue([for device in var.boot_order : can(regex("^(scsi|virtio|sata|ide|net)[0-9]+$", device))])
    error_message = "boot_order entries must be devices such as scsi0, ide3 or net0."
  }
}

variable "network_devices" {
  description = "Network interfaces, in order (net0, net1...). A vlan_id is for a VLAN-aware bridge."
  type = list(object({
    bridge      = string
    model       = optional(string, "virtio")
    vlan_id     = optional(number)
    mac_address = optional(string)
    firewall    = optional(bool, false)
  }))
  nullable = false

  validation {
    condition     = length(var.network_devices) >= 1
    error_message = "At least one network device is required."
  }

  validation {
    condition     = alltrue([for nic in var.network_devices : nic.vlan_id == null ? true : (nic.vlan_id >= 1 && nic.vlan_id <= 4094)])
    error_message = "vlan_id must be between 1 and 4094."
  }

  validation {
    condition     = alltrue([for nic in var.network_devices : nic.mac_address == null ? true : can(regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", nic.mac_address))])
    error_message = "mac_address must look like AA:BB:CC:DD:EE:FF."
  }
}

variable "cloud_init" {
  description = <<-EOT
    Cloud-init drive. Null adds none. Talos reads the network settings from it (platform nocloud).
    - datastore_id: datastore of the cloud-init drive.
    - interface: IDE interface of the drive.
    - ip_configs: one entry per network device, in the same order. An address is dhcp or a CIDR such as 192.0.2.10/24.
    - dns: DNS servers and search domain.
    - user_data_file_id, vendor_data_file_id: ID of a snippet file with custom data (keeps secrets out of the module).
  EOT
  type = object({
    datastore_id = string
    interface    = optional(string, "ide2")
    ip_configs = optional(list(object({
      ipv4 = optional(object({
        address = string
        gateway = optional(string)
      }))
      ipv6 = optional(object({
        address = string
        gateway = optional(string)
      }))
    })), [])
    dns = optional(object({
      servers = list(string)
      domain  = optional(string)
    }))
    user_data_file_id   = optional(string)
    vendor_data_file_id = optional(string)
  })
  default = null

  validation {
    condition     = var.cloud_init == null ? true : can(regex("^(ide|sata)[0-9]+$", var.cloud_init.interface))
    error_message = "cloud_init.interface must be an ide or sata interface such as ide2."
  }

  validation {
    condition     = var.cloud_init == null ? true : !contains(keys(var.disks), var.cloud_init.interface)
    error_message = "cloud_init.interface is already used by a disk."
  }

  validation {
    condition     = var.cloud_init == null ? true : length(var.cloud_init.ip_configs) <= length(var.network_devices)
    error_message = "cloud_init.ip_configs has more entries than network_devices."
  }

  validation {
    condition = var.cloud_init == null ? true : alltrue([
      for ip in var.cloud_init.ip_configs :
      (ip.ipv4 == null ? true : (ip.ipv4.address == "dhcp" || can(cidrhost(ip.ipv4.address, 0)))) &&
      (ip.ipv4 == null || ip.ipv4.gateway == null ? true : can(cidrhost("${ip.ipv4.gateway}/32", 0)))
    ])
    error_message = "An IPv4 address must be dhcp or a CIDR such as 192.0.2.10/24, and a gateway must be an IPv4 address."
  }

  validation {
    condition = var.cloud_init == null ? true : alltrue([
      for ip in var.cloud_init.ip_configs :
      (ip.ipv6 == null ? true : (contains(["dhcp", "auto"], ip.ipv6.address) || can(cidrhost(ip.ipv6.address, 0)))) &&
      (ip.ipv6 == null || ip.ipv6.gateway == null ? true : can(cidrhost("${ip.ipv6.gateway}/128", 0)))
    ])
    error_message = "An IPv6 address must be dhcp, auto or a CIDR such as 2001:db8::10/64, and a gateway must be an IPv6 address."
  }

  validation {
    condition = var.cloud_init == null || var.cloud_init.dns == null ? true : alltrue([
      for server in var.cloud_init.dns.servers :
      can(cidrhost("${server}/${strcontains(server, ":") ? 128 : 32}", 0))
    ])
    error_message = "DNS servers must be IP addresses."
  }
}

variable "cloud_init_user_account" {
  description = "User account created by cloud-init. Null creates none. Talos does not use it. The password ends up in the Terraform state: prefer SSH keys, or a user_data_file_id snippet."
  type = object({
    username = string
    password = optional(string)
    keys     = optional(list(string), [])
  })
  default   = null
  sensitive = true

  validation {
    condition     = var.cloud_init_user_account == null ? true : var.cloud_init != null
    error_message = "cloud_init_user_account needs cloud_init: the account lives on the cloud-init drive."
  }
}
