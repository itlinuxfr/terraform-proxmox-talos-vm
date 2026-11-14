# Input validation tests: each rejected value must fail the plan on the right variable.

mock_provider "proxmox" {}

variables {
  node_name = "pve-test"
  name      = "talos-cp-1"
  disks = {
    scsi0 = { datastore_id = "local-lvm", size_gb = 20 }
  }
  network_devices = [{ bridge = "vmbr0" }]
}

run "empty_node_name_refused" {
  command = plan
  variables { node_name = " " }
  expect_failures = [var.node_name]
}

run "uppercase_name_refused" {
  command = plan
  variables { name = "Talos_CP1" }
  expect_failures = [var.name]
}

run "name_starting_with_hyphen_refused" {
  command = plan
  variables { name = "-talos" }
  expect_failures = [var.name]
}

run "vm_id_too_small_refused" {
  command = plan
  variables { vm_id = 50 }
  expect_failures = [var.vm_id]
}

run "invalid_machine_refused" {
  command = plan
  variables { machine = "i440fx" }
  expect_failures = [var.machine]
}

run "invalid_bios_refused" {
  command = plan
  variables { firmware = { bios = "uefi" } }
  expect_failures = [var.firmware]
}

run "invalid_tpm_version_refused" {
  command = plan
  variables { tpm = { version = "v3.0" } }
  expect_failures = [var.tpm]
}

run "zero_cores_refused" {
  command = plan
  variables { cpu = { cores = 0 } }
  expect_failures = [var.cpu]
}

run "memory_too_small_refused" {
  command = plan
  variables { memory = { dedicated_mb = 128 } }
  expect_failures = [var.memory]
}

run "floating_memory_above_dedicated_refused" {
  command = plan
  variables { memory = { dedicated_mb = 2048, floating_mb = 4096 } }
  expect_failures = [var.memory]
}

run "invalid_scsi_hardware_refused" {
  command = plan
  variables { scsi_hardware = "sata" }
  expect_failures = [var.scsi_hardware]
}

run "no_disk_refused" {
  command = plan
  variables { disks = {} }
  expect_failures = [var.disks]
}

run "invalid_disk_interface_refused" {
  command = plan
  variables {
    disks = { disk0 = { datastore_id = "local-lvm", size_gb = 20 } }
  }
  expect_failures = [var.disks]
}

run "zero_disk_size_refused" {
  command = plan
  variables {
    disks = { scsi0 = { datastore_id = "local-lvm", size_gb = 0 } }
  }
  expect_failures = [var.disks]
}

run "cdrom_on_a_disk_interface_refused" {
  command = plan
  variables {
    cdrom = { file_id = "local:iso/talos.iso", interface = "ide0" }
    disks = { ide0 = { datastore_id = "local-lvm", size_gb = 20 } }
  }
  expect_failures = [var.cdrom]
}

run "cdrom_on_cloud_init_interface_refused" {
  command = plan
  variables {
    cdrom      = { file_id = "local:iso/talos.iso", interface = "ide2" }
    cloud_init = { datastore_id = "local-lvm" }
  }
  expect_failures = [var.cdrom]
}

run "invalid_boot_order_refused" {
  command = plan
  variables { boot_order = ["disk"] }
  expect_failures = [var.boot_order]
}

run "no_network_device_refused" {
  command = plan
  variables { network_devices = [] }
  expect_failures = [var.network_devices]
}

run "vlan_out_of_range_refused" {
  command = plan
  variables { network_devices = [{ bridge = "vmbr0", vlan_id = 5000 }] }
  expect_failures = [var.network_devices]
}

run "invalid_mac_address_refused" {
  command = plan
  variables { network_devices = [{ bridge = "vmbr0", mac_address = "not-a-mac" }] }
  expect_failures = [var.network_devices]
}

run "cloud_init_on_a_disk_interface_refused" {
  command = plan
  variables {
    cloud_init = { datastore_id = "local-lvm", interface = "ide0" }
    disks      = { ide0 = { datastore_id = "local-lvm", size_gb = 20 } }
  }
  expect_failures = [var.cloud_init]
}

run "more_ip_configs_than_network_devices_refused" {
  command = plan
  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      ip_configs   = [{ ipv4 = { address = "dhcp" } }, { ipv4 = { address = "dhcp" } }]
    }
  }
  expect_failures = [var.cloud_init]
}

run "invalid_ipv4_address_refused" {
  command = plan
  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      ip_configs   = [{ ipv4 = { address = "192.0.2.10" } }]
    }
  }
  expect_failures = [var.cloud_init]
}

run "invalid_ipv4_gateway_refused" {
  command = plan
  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      ip_configs   = [{ ipv4 = { address = "192.0.2.10/24", gateway = "not-an-ip" } }]
    }
  }
  expect_failures = [var.cloud_init]
}

run "invalid_ipv6_address_refused" {
  command = plan
  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      ip_configs   = [{ ipv6 = { address = "2001:db8::10" } }]
    }
  }
  expect_failures = [var.cloud_init]
}

run "invalid_dns_server_refused" {
  command = plan
  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      dns          = { servers = ["dns.example.test"] }
    }
  }
  expect_failures = [var.cloud_init]
}

run "user_account_without_cloud_init_refused" {
  command = plan
  variables {
    cloud_init_user_account = { username = "admin" }
  }
  expect_failures = [var.cloud_init_user_account]
}

run "iothread_on_scsi_without_single_controller_refused" {
  command = plan
  variables {
    disks = { scsi0 = { datastore_id = "local-lvm", size_gb = 20, iothread = true } }
  }
  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "iothread_on_virtio_disk_accepted" {
  command = plan
  variables {
    disks = { virtio0 = { datastore_id = "local-lvm", size_gb = 20, iothread = true } }
  }
}
