resource "proxmox_virtual_environment_vm" "this" {
  node_name   = var.proxmox_node
  name        = var.vm_name
  description = var.vm_description
  tags        = var.vm_tags
  on_boot     = var.vm_onboot
  started     = var.vm_start

  machine         = var.vm_machine_type
  bios            = var.vm_bios
  scsi_hardware   = var.vm_scsi_hardware
  stop_on_destroy = true

  agent {
    enabled = var.vm_guest_agent
    trim    = true
  }

  cpu {
    type    = var.vm_cpu_type
    sockets = var.vm_sockets
    cores   = var.vm_cores
    numa    = true
  }

  memory {
    dedicated = var.vm_memory
    floating  = 0
  }

  cdrom {
    file_id   = var.vm_iso
    interface = "ide2"
  }

  operating_system {
    type = "l26" # Linux 2.6+
  }

  # Dynamic Network Configuration
  dynamic "network_device" {
    for_each = var.vm_network
    content {
      bridge      = network_device.value.bridge
      model       = network_device.value.model
      mac_address = network_device.value.mac_addr
      vlan_id     = network_device.value.tag
      firewall    = network_device.value.firewall
    }
  }

  # Dynamic Disk Configuration
  dynamic "disk" {
    for_each = var.vm_disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size_gb
      file_format  = disk.value.format
      ssd          = disk.value.ssd
      discard      = disk.value.discard ? "on" : "ignore"
      iothread     = disk.value.iothread
    }
  }

  # Cloud-Init (Optional)
  dynamic "initialization" {
    for_each = var.vm_cloudinit_datastore != null ? [1] : []
    content {
      datastore_id = var.vm_cloudinit_datastore

      dynamic "ip_config" {
        for_each = var.vm_cloudinit_ip_config
        content {
          ipv4 {
            address = ip_config.value.ipv4.address
            gateway = ip_config.value.ipv4.gateway
          }
        }
      }
    }
  }
}
