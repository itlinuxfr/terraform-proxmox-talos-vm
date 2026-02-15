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

run "invalid_bios" {
  command = plan

  variables {
    proxmox_node = "pve-test"
    vm_name      = "test-vm"
    vm_iso       = "local:iso/test.iso"
    vm_bios      = "legacy" # Invalid, must be seabios or ovmf

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
