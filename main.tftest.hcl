provider "proxmox" {
  endpoint  = "https://localhost:8006/"
  api_token = "user@pam!token=secret"
  insecure  = true
  ssh {
    agent = false
  }
}

run "valid_plan" {
  command = plan

  variables {
    proxmox_node = "pve-test"
    vm_name      = "test-vm"
    vm_iso       = "local:iso/test.iso"

    vm_disks = [
      {
        datastore_id = "local"
        interface    = "scsi0"
        size_gb      = 10
      }
    ]
  }
}

# Invalid BIOS
run "invalid_bios" {
  command = plan

  variables {
    proxmox_node = "pve-test"
    vm_name      = "test-vm"
    vm_iso       = "local:iso/test.iso"
    vm_bios      = "legacy"

    vm_disks = [
      {
        datastore_id = "local"
        interface    = "scsi0"
        size_gb      = 10
      }
    ]
  }

  expect_failures = [
    var.vm_bios
  ]
}

# Invalid Memory
run "invalid_memory" {
  command = plan

  variables {
    proxmox_node = "pve-test"
    vm_name      = "test-vm"
    vm_iso       = "local:iso/test.iso"
    vm_memory    = 256 # Too low

    vm_disks = [
      {
        datastore_id = "local"
        interface    = "scsi0"
        size_gb      = 10
      }
    ]
  }

  expect_failures = [
    var.vm_memory
  ]
}

# Invalid Disk Format
run "invalid_disk_format" {
  command = plan

  variables {
    proxmox_node = "pve-test"
    vm_name      = "test-vm"
    vm_iso       = "local:iso/test.iso"

    vm_disks = [
      {
        datastore_id = "local"
        interface    = "scsi0"
        size_gb      = 10
        format       = "iso" # invalid
      }
    ]
  }

  expect_failures = [
    var.vm_disks
  ]
}

# Invalid Network Model
run "invalid_network_model" {
  command = plan

  variables {
    proxmox_node = "pve-test"
    vm_name      = "test-vm"
    vm_iso       = "local:iso/test.iso"

    vm_network = [
      {
        bridge = "vmbr0"
        model  = "realtek" # invalid
      }
    ]

    vm_disks = [
      {
        datastore_id = "local"
        interface    = "scsi0"
        size_gb      = 10
      }
    ]
  }

  expect_failures = [
    var.vm_network
  ]
}
