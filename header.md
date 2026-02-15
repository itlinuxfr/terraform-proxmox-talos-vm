[![terraform-docs](https://github.com/itlinuxfr/terraform-proxmox-talos-vm/actions/workflows/documentation.yaml/badge.svg)](https://github.com/itlinuxfr/terraform-proxmox-talos-vm/actions/workflows/documentation.yaml)
[![terraform-lint](https://github.com/itlinuxfr/terraform-proxmox-talos-vm/actions/workflows/tflint.yaml/badge.svg)](https://github.com/itlinuxfr/terraform-proxmox-talos-vm/actions/workflows/tflint.yaml)
[![Provider: bpg/proxmox](https://img.shields.io/badge/provider-bpg%2Fproxmox-623CE4?logo=terraform)](https://registry.terraform.io/providers/bpg/proxmox/latest)

# Usage

```hcl
module "talos_vm" {
  source = "./modules/proxmox_talos_vm"

  proxmox_node   = "pve-01"
  vm_name        = "talos-cp-01"
  vm_iso         = "local:iso/talos.iso"
  
  vm_cpu_type = "host"
  vm_sockets  = 1
  vm_cores    = 4
  vm_memory   = 4096

  vm_network = [
    {
      bridge = "vmbr0"
      model  = "virtio"
    },
    {
      bridge = "vmbr1" # Private network
      model  = "virtio"
    }
  ]

  vm_disks = [
    {
      datastore_id = "local-zfs"
      interface    = "scsi0"
      size_gb      = 20
      ssd          = true
      discard      = true
    }
  ]
}
```
