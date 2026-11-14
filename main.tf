# Creates one Proxmox virtual machine meant to run a Talos Linux node.
# One VM per call: to create several nodes, put for_each on the module call.
# Talos boots from an image (CD-ROM) or from an imported disk image, and reads its network settings from cloud-init.

locals {
  # Interfaces sort alphabetically: scsi0 comes before scsi1. The first one boots.
  boot_disk = sort(keys(var.disks))[0]

  # Datastore of the first disk: the default for the EFI disk and the TPM state.
  default_datastore = var.disks[local.boot_disk].datastore_id

  boot_order = var.boot_order != null ? var.boot_order : concat([local.boot_disk], var.cdrom != null ? [var.cdrom.interface] : [])
}

resource "proxmox_virtual_environment_vm" "this" {
  node_name   = var.node_name
  name        = var.name
  vm_id       = var.vm_id
  description = var.description
  tags        = var.tags
  pool_id     = var.pool_id

  started         = var.started
  on_boot         = var.on_boot
  stop_on_destroy = var.stop_on_destroy

  machine       = var.machine
  bios          = var.firmware.bios
  scsi_hardware = var.scsi_hardware
  boot_order    = local.boot_order

  operating_system {
    type = var.operating_system_type
  }

  agent {
    enabled = var.agent.enabled
    trim    = var.agent.trim
  }

  cpu {
    type    = var.cpu.type
    cores   = var.cpu.cores
    sockets = var.cpu.sockets
    numa    = var.cpu.numa
  }

  memory {
    dedicated = var.memory.dedicated_mb
    floating  = var.memory.floating_mb
  }

  dynamic "efi_disk" {
    for_each = var.firmware.bios == "ovmf" ? [var.firmware] : []

    content {
      datastore_id      = coalesce(efi_disk.value.efi_datastore_id, local.default_datastore)
      file_format       = "raw"
      type              = "4m"
      pre_enrolled_keys = efi_disk.value.pre_enrolled_keys
    }
  }

  dynamic "tpm_state" {
    for_each = var.tpm != null ? [var.tpm] : []

    content {
      datastore_id = coalesce(tpm_state.value.datastore_id, local.default_datastore)
      version      = tpm_state.value.version
    }
  }

  dynamic "disk" {
    for_each = var.disks

    content {
      interface    = disk.key
      datastore_id = disk.value.datastore_id
      size         = disk.value.size_gb
      file_format  = disk.value.file_format
      ssd          = disk.value.ssd
      discard      = disk.value.discard ? "on" : "ignore"
      iothread     = disk.value.iothread
      import_from  = disk.value.import_from
    }
  }

  dynamic "cdrom" {
    for_each = var.cdrom != null ? [var.cdrom] : []

    content {
      file_id   = cdrom.value.file_id
      interface = cdrom.value.interface
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices

    content {
      bridge      = network_device.value.bridge
      model       = network_device.value.model
      vlan_id     = network_device.value.vlan_id
      mac_address = network_device.value.mac_address
      firewall    = network_device.value.firewall
    }
  }

  dynamic "initialization" {
    for_each = var.cloud_init != null ? [var.cloud_init] : []

    content {
      datastore_id        = initialization.value.datastore_id
      interface           = initialization.value.interface
      user_data_file_id   = initialization.value.user_data_file_id
      vendor_data_file_id = initialization.value.vendor_data_file_id

      dynamic "ip_config" {
        for_each = initialization.value.ip_configs

        content {
          dynamic "ipv4" {
            for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []

            content {
              address = ipv4.value.address
              gateway = ipv4.value.gateway
            }
          }

          dynamic "ipv6" {
            for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []

            content {
              address = ipv6.value.address
              gateway = ipv6.value.gateway
            }
          }
        }
      }

      dynamic "dns" {
        for_each = initialization.value.dns != null ? [initialization.value.dns] : []

        content {
          servers = dns.value.servers
          domain  = dns.value.domain
        }
      }

      dynamic "user_account" {
        for_each = var.cloud_init_user_account != null ? [var.cloud_init_user_account] : []

        content {
          username = user_account.value.username
          password = user_account.value.password
          keys     = user_account.value.keys
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !anytrue([for interface, disk in var.disks : disk.iothread && startswith(interface, "scsi")]) || var.scsi_hardware == "virtio-scsi-single"
      error_message = "A SCSI disk with iothread needs scsi_hardware = virtio-scsi-single. Turn iothread off, or use a virtio disk."
    }
  }
}
