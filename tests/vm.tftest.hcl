# Tests without real infrastructure: the Proxmox provider is replaced by a mock provider.
# `command = plan` creates nothing. Attributes that Proxmox computes (ID, IP addresses) are not checked here.

mock_provider "proxmox" {}

variables {
  node_name = "pve-test"
  name      = "talos-cp-1"
  disks = {
    scsi0 = { datastore_id = "local-lvm", size_gb = 20 }
  }
  network_devices = [{ bridge = "vmbr0" }]
}

run "minimal_vm_defaults" {
  command = plan

  assert {
    condition = (
      proxmox_virtual_environment_vm.this.machine == "q35" &&
      proxmox_virtual_environment_vm.this.bios == "seabios" &&
      proxmox_virtual_environment_vm.this.scsi_hardware == "virtio-scsi-pci" &&
      proxmox_virtual_environment_vm.this.started == true &&
      proxmox_virtual_environment_vm.this.on_boot == true &&
      proxmox_virtual_environment_vm.this.stop_on_destroy == true
    )
    error_message = "Defaults must be: q35, seabios, virtio-scsi-pci, started, on_boot, stop_on_destroy."
  }

  assert {
    condition = (
      proxmox_virtual_environment_vm.this.cpu[0].type == "host" &&
      proxmox_virtual_environment_vm.this.cpu[0].cores == 2 &&
      proxmox_virtual_environment_vm.this.cpu[0].sockets == 1 &&
      proxmox_virtual_environment_vm.this.memory[0].dedicated == 2048 &&
      proxmox_virtual_environment_vm.this.memory[0].floating == 0
    )
    error_message = "Defaults must be: host CPU, 2 cores, 1 socket, 2048 MiB, no ballooning."
  }

  assert {
    condition = (
      length(proxmox_virtual_environment_vm.this.efi_disk) == 0 &&
      length(proxmox_virtual_environment_vm.this.tpm_state) == 0 &&
      length(proxmox_virtual_environment_vm.this.cdrom) == 0 &&
      length(proxmox_virtual_environment_vm.this.initialization) == 0
    )
    error_message = "Without options there must be no EFI disk, no TPM, no CD-ROM and no cloud-init drive."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.boot_order == tolist(["scsi0"])
    error_message = "The VM must boot from the first disk when there is no CD-ROM."
  }
}

run "iso_boot_with_cdrom" {
  command = plan

  variables {
    cdrom = { file_id = "local:iso/talos.iso" }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.cdrom[0].interface == "ide3" && proxmox_virtual_environment_vm.this.cdrom[0].file_id == "local:iso/talos.iso"
    error_message = "The CD-ROM must use ide3 by default and the given file."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.boot_order == tolist(["scsi0", "ide3"])
    error_message = "The boot order must be the disk first, then the CD-ROM."
  }
}

run "explicit_boot_order" {
  command = plan

  variables {
    cdrom      = { file_id = "local:iso/talos.iso" }
    boot_order = ["ide3", "scsi0"]
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.boot_order == tolist(["ide3", "scsi0"])
    error_message = "An explicit boot_order must be kept as given."
  }
}

run "disk_image_import" {
  command = plan

  variables {
    disks = {
      scsi0 = { datastore_id = "local-lvm", size_gb = 20, import_from = "local:import/talos.qcow2" }
    }
  }

  assert {
    condition     = one([for d in proxmox_virtual_environment_vm.this.disk : d.import_from if d.interface == "scsi0"]) == "local:import/talos.qcow2"
    error_message = "import_from must reach the disk."
  }
}

run "several_disks_and_discard" {
  command = plan

  variables {
    disks = {
      scsi1 = { datastore_id = "local-lvm", size_gb = 100, discard = false }
      scsi0 = { datastore_id = "local-lvm", size_gb = 20 }
    }
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.disk) == 2
    error_message = "Both disks must be created."
  }

  assert {
    condition = (
      one([for d in proxmox_virtual_environment_vm.this.disk : d.discard if d.interface == "scsi0"]) == "on" &&
      one([for d in proxmox_virtual_environment_vm.this.disk : d.discard if d.interface == "scsi1"]) == "ignore"
    )
    error_message = "discard must map to on, or ignore when false."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.boot_order == tolist(["scsi0"])
    error_message = "The first interface in alphabetical order must be the boot disk, whatever the key order."
  }
}

run "secure_boot_and_tpm" {
  command = plan

  variables {
    firmware = { bios = "ovmf" }
    tpm      = {}
  }

  assert {
    condition = (
      proxmox_virtual_environment_vm.this.bios == "ovmf" &&
      proxmox_virtual_environment_vm.this.efi_disk[0].datastore_id == "local-lvm" &&
      proxmox_virtual_environment_vm.this.efi_disk[0].pre_enrolled_keys == false &&
      proxmox_virtual_environment_vm.this.efi_disk[0].type == "4m"
    )
    error_message = "ovmf must add an EFI disk without pre-enrolled keys, on the datastore of the first disk."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.tpm_state[0].version == "v2.0" && proxmox_virtual_environment_vm.this.tpm_state[0].datastore_id == "local-lvm"
    error_message = "An empty tpm object must add a TPM 2.0 on the datastore of the first disk."
  }
}

run "secure_boot_datastores_overridden" {
  command = plan

  variables {
    firmware = { bios = "ovmf", efi_datastore_id = "fast" }
    tpm      = { datastore_id = "fast", version = "v1.2" }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.efi_disk[0].datastore_id == "fast" && proxmox_virtual_environment_vm.this.tpm_state[0].datastore_id == "fast" && proxmox_virtual_environment_vm.this.tpm_state[0].version == "v1.2"
    error_message = "efi_datastore_id and the tpm settings must be used."
  }
}

run "cloud_init_static_network" {
  command = plan

  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      ip_configs   = [{ ipv4 = { address = "192.0.2.10/24", gateway = "192.0.2.1" } }]
      dns          = { servers = ["192.0.2.53", "2001:db8::53"], domain = "example.test" }
    }
  }

  assert {
    condition = (
      proxmox_virtual_environment_vm.this.initialization[0].interface == "ide2" &&
      proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address == "192.0.2.10/24" &&
      proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].gateway == "192.0.2.1"
    )
    error_message = "The cloud-init drive must use ide2 and carry the static IPv4 address and gateway."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].dns[0].servers == tolist(["192.0.2.53", "2001:db8::53"]) && proxmox_virtual_environment_vm.this.initialization[0].dns[0].domain == "example.test"
    error_message = "DNS servers and domain must reach cloud-init."
  }
}

run "cloud_init_without_user_account" {
  command = plan

  variables {
    cloud_init = {
      datastore_id = "local-lvm"
      ip_configs   = [{ ipv4 = { address = "dhcp" } }]
    }
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].user_account) == 0
    error_message = "No user account must be created unless cloud_init_user_account is set."
  }
}

run "cloud_init_user_account_and_snippets" {
  command = plan

  variables {
    cloud_init = {
      datastore_id      = "local-lvm"
      user_data_file_id = "local:snippets/user-data.yaml"
    }
    cloud_init_user_account = {
      username = "admin"
      keys     = ["ssh-ed25519 AAAA test"]
    }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.initialization[0].user_data_file_id == "local:snippets/user-data.yaml"
    error_message = "user_data_file_id must reach cloud-init."
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.initialization[0].user_account) == 1
    error_message = "cloud_init_user_account must create a user account."
  }
}

run "network_devices_vlan_and_mac" {
  command = plan

  variables {
    network_devices = [
      { bridge = "vmbr0", vlan_id = 700, mac_address = "BC:24:11:00:00:01", firewall = true },
      { bridge = "vmbr1" },
    ]
  }

  assert {
    condition     = length(proxmox_virtual_environment_vm.this.network_device) == 2
    error_message = "Both network devices must be created."
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.network_device[0].vlan_id == 700 && proxmox_virtual_environment_vm.this.network_device[0].firewall == true
    error_message = "vlan_id and firewall must reach the first network device."
  }
}

run "vm_id_and_pool" {
  command = plan

  variables {
    vm_id   = 7001
    pool_id = "k8s-prod"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.vm_id == 7001 && proxmox_virtual_environment_vm.this.pool_id == "k8s-prod"
    error_message = "vm_id and pool_id must reach the provider."
  }
}

run "iothread_with_single_controller" {
  command = plan

  variables {
    scsi_hardware = "virtio-scsi-single"
    disks = {
      scsi0 = { datastore_id = "local-lvm", size_gb = 20, iothread = true }
    }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.this.scsi_hardware == "virtio-scsi-single"
    error_message = "iothread must be accepted with virtio-scsi-single."
  }
}
