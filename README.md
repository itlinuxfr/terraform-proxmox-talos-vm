<!-- BEGIN_TF_DOCS -->
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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.95.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | ~> 0.95.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_proxmox_node"></a> [proxmox\_node](#input\_proxmox\_node) | Target Proxmox Node Name | `string` | n/a | yes |
| <a name="input_vm_bios"></a> [vm\_bios](#input\_vm\_bios) | BIOS type (seabios or ovmf) | `string` | `"seabios"` | no |
| <a name="input_vm_cloudinit_datastore"></a> [vm\_cloudinit\_datastore](#input\_vm\_cloudinit\_datastore) | Datastore for Cloud-Init drive | `string` | `null` | no |
| <a name="input_vm_cloudinit_interface"></a> [vm\_cloudinit\_interface](#input\_vm\_cloudinit\_interface) | Interface for Cloud-Init drive (e.g., scsi30, ide3) | `string` | `"scsi30"` | no |
| <a name="input_vm_cloudinit_ip_config"></a> [vm\_cloudinit\_ip\_config](#input\_vm\_cloudinit\_ip\_config) | Cloud-Init IP Configuration (list of configs matching network interfaces) | <pre>list(object({<br/>    ipv4 = object({<br/>      address = string<br/>      gateway = optional(string)<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_vm_cores"></a> [vm\_cores](#input\_vm\_cores) | Number of CPU cores per socket | `number` | `2` | no |
| <a name="input_vm_cpu_type"></a> [vm\_cpu\_type](#input\_vm\_cpu\_type) | CPU type (host recommended for performance) | `string` | `"host"` | no |
| <a name="input_vm_description"></a> [vm\_description](#input\_vm\_description) | Description of the VM | `string` | `"Managed by Terraform"` | no |
| <a name="input_vm_disks"></a> [vm\_disks](#input\_vm\_disks) | List of disks | <pre>list(object({<br/>    datastore_id = string<br/>    interface    = string # scsi, virtio, sata<br/>    size_gb      = number<br/>    format       = optional(string, "raw")<br/>    ssd          = optional(bool, true) # Recommended for etcd<br/>    discard      = optional(bool, true)<br/>    iothread     = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_vm_guest_agent"></a> [vm\_guest\_agent](#input\_vm\_guest\_agent) | Enable QEMU Guest Agent | `bool` | `true` | no |
| <a name="input_vm_iso"></a> [vm\_iso](#input\_vm\_iso) | ISO File ID to mount (e.g., local:iso/talos.iso) | `string` | n/a | yes |
| <a name="input_vm_machine_type"></a> [vm\_machine\_type](#input\_vm\_machine\_type) | Machine type (q35 recommended for Talos) | `string` | `"q35"` | no |
| <a name="input_vm_memory"></a> [vm\_memory](#input\_vm\_memory) | Memory in MiB | `number` | `2048` | no |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | Name of the VM (will also be used as hostname) | `string` | n/a | yes |
| <a name="input_vm_network"></a> [vm\_network](#input\_vm\_network) | List of network interfaces | <pre>list(object({<br/>    bridge   = string<br/>    model    = optional(string, "virtio")<br/>    mac_addr = optional(string)<br/>    tag      = optional(number)<br/>    firewall = optional(bool, false)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "bridge": "vmbr0",<br/>    "model": "virtio"<br/>  }<br/>]</pre> | no |
| <a name="input_vm_onboot"></a> [vm\_onboot](#input\_vm\_onboot) | Start VM on node boot | `bool` | `true` | no |
| <a name="input_vm_scsi_hardware"></a> [vm\_scsi\_hardware](#input\_vm\_scsi\_hardware) | SCSI controller model (virtio-scsi-pci recommended for Talos) | `string` | `"virtio-scsi-pci"` | no |
| <a name="input_vm_sockets"></a> [vm\_sockets](#input\_vm\_sockets) | Number of CPU sockets | `number` | `1` | no |
| <a name="input_vm_start"></a> [vm\_start](#input\_vm\_start) | Start VM after creation | `bool` | `true` | no |
| <a name="input_vm_tags"></a> [vm\_tags](#input\_vm\_tags) | List of tags to apply to the VM | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ipv4_addresses"></a> [ipv4\_addresses](#output\_ipv4\_addresses) | List of IPv4 addresses assigned to the VM |
| <a name="output_mac_addresses"></a> [mac\_addresses](#output\_mac\_addresses) | List of MAC addresses assigned to the VM |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | The ID of the VM |
<!-- END_TF_DOCS -->