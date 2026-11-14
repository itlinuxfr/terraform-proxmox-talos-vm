# terraform-proxmox-talos-vm

Creates one Proxmox virtual machine meant to run a [Talos Linux](https://www.talos.dev) node. The VM boots Talos from an ISO (CD-ROM) or
from an imported disk image, reads its network settings from cloud-init, and can use UEFI SecureBoot and a TPM 2.0. The module does not
download the image and does not configure Talos: use `terraform-talos-image`, `terraform-proxmox-download-file` and the Talos provider for that.

## Usage

```hcl
module "node" {
  source = "git::https://github.com/itlinuxfr/terraform-proxmox-talos-vm.git?ref=v1.0.0"

  node_name = "pve-01"
  name      = "talos-cp-1"

  disks           = { scsi0 = { datastore_id = "local-zfs", size_gb = 20 } }
  network_devices = [{ bridge = "vmbr0" }]
  cdrom           = { file_id = "local:iso/talos.iso" }

  cloud_init = {
    datastore_id = "local-zfs"
    ip_configs   = [{ ipv4 = { address = "192.0.2.10/24", gateway = "192.0.2.1" } }]
    dns          = { servers = ["192.0.2.53"] }
  }
}
```

One VM per call. To create several nodes, put `for_each` on the module call.

Defaults: BIOS boot (no SecureBoot, no TPM), q35 machine, host CPU with 2 cores, 2 GiB of memory without ballooning, guest agent on, and
a boot order of the first disk then the CD-ROM. On the first boot the empty disk is skipped, so the image takes over, and the installed system boots afterwards.
SecureBoot and the TPM are opt-in (`firmware = { bios = "ovmf" }` and `tpm = {}`) and need a SecureBoot image.

See the [`examples/`](examples/) directory for an ISO node, a SecureBoot node with a TPM, and a node created from a disk image.

## Upgrading from the previous version
The variables were renamed and regrouped (`vm_name` is now `name`, `proxmox_node` is `node_name`, `vm_disks` is `disks`, and so on).
The resource keeps its address (`proxmox_virtual_environment_vm.this`), so no `moved` block is needed inside the module. When you move
existing VMs under this module, add `moved` blocks in your root module and check that `terraform plan` shows a move, not a replacement.

## Contributing
Read [`AGENTS.md`](AGENTS.md) for conventions and commands, and [`SECURITY.md`](SECURITY.md) for security rules.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.100.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >= 0.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disks"></a> [disks](#input\_disks) | Disks, keyed by Proxmox interface (scsi0, virtio0, sata0, ide0...). The first key in alphabetical order is the boot disk.<br/>- size\_gb: disk size in GiB. With import\_from it must be at least the size of the image.<br/>- import\_from: ID of a disk image to import, for example the id output of terraform-proxmox-download-file with the import content type. Used at creation only.<br/>- discard: pass trim requests to the storage. iothread needs scsi\_hardware = virtio-scsi-single. | <pre>map(object({<br/>    datastore_id = string<br/>    size_gb      = number<br/>    file_format  = optional(string, "raw")<br/>    ssd          = optional(bool, true)<br/>    discard      = optional(bool, true)<br/>    iothread     = optional(bool, false)<br/>    import_from  = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | VM name. Proxmox gives it to cloud-init, and Talos uses it as the hostname: lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_network_devices"></a> [network\_devices](#input\_network\_devices) | Network interfaces, in order (net0, net1...). A vlan\_id is for a VLAN-aware bridge. | <pre>list(object({<br/>    bridge      = string<br/>    model       = optional(string, "virtio")<br/>    vlan_id     = optional(number)<br/>    mac_address = optional(string)<br/>    firewall    = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Name of the Proxmox node that runs the VM. | `string` | n/a | yes |
| <a name="input_agent"></a> [agent](#input\_agent) | QEMU guest agent. Talos needs the siderolabs/qemu-guest-agent extension in its image for the VM to report its IP addresses. | <pre>object({<br/>    enabled = optional(bool, true)<br/>    trim    = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_boot_order"></a> [boot\_order](#input\_boot\_order) | Boot order, for example ["scsi0", "ide3"]. Null boots from the first disk, then from the CD-ROM: the empty disk is skipped on the first boot, so the image takes over, and the installed system boots afterwards. | `list(string)` | `null` | no |
| <a name="input_cdrom"></a> [cdrom](#input\_cdrom) | CD-ROM with a boot image, for example the id output of terraform-proxmox-download-file. Null adds none. The default interface ide3 leaves ide2 to the cloud-init drive. | <pre>object({<br/>    file_id   = string<br/>    interface = optional(string, "ide3")<br/>  })</pre> | `null` | no |
| <a name="input_cloud_init"></a> [cloud\_init](#input\_cloud\_init) | Cloud-init drive. Null adds none. Talos reads the network settings from it (platform nocloud).<br/>- datastore\_id: datastore of the cloud-init drive.<br/>- interface: IDE interface of the drive.<br/>- ip\_configs: one entry per network device, in the same order. An address is dhcp or a CIDR such as 192.0.2.10/24.<br/>- dns: DNS servers and search domain.<br/>- user\_data\_file\_id, vendor\_data\_file\_id: ID of a snippet file with custom data (keeps secrets out of the module). | <pre>object({<br/>    datastore_id = string<br/>    interface    = optional(string, "ide2")<br/>    ip_configs = optional(list(object({<br/>      ipv4 = optional(object({<br/>        address = string<br/>        gateway = optional(string)<br/>      }))<br/>      ipv6 = optional(object({<br/>        address = string<br/>        gateway = optional(string)<br/>      }))<br/>    })), [])<br/>    dns = optional(object({<br/>      servers = list(string)<br/>      domain  = optional(string)<br/>    }))<br/>    user_data_file_id   = optional(string)<br/>    vendor_data_file_id = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_cloud_init_user_account"></a> [cloud\_init\_user\_account](#input\_cloud\_init\_user\_account) | User account created by cloud-init. Null creates none. Talos does not use it. The password ends up in the Terraform state: prefer SSH keys, or a user\_data\_file\_id snippet. | <pre>object({<br/>    username = string<br/>    password = optional(string)<br/>    keys     = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU. type host gives the guest the real CPU features (Talos needs x86-64-v2). | <pre>object({<br/>    type    = optional(string, "host")<br/>    cores   = optional(number, 2)<br/>    sockets = optional(number, 1)<br/>    numa    = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | VM description. | `string` | `null` | no |
| <a name="input_firmware"></a> [firmware](#input\_firmware) | Firmware.<br/>- bios: seabios (legacy BIOS) or ovmf (UEFI). ovmf adds an EFI disk, which SecureBoot needs.<br/>- efi\_datastore\_id: datastore of the EFI disk. Null uses the datastore of the first disk.<br/>- pre\_enrolled\_keys: boot with the Microsoft keys already enrolled. Keep false for Talos SecureBoot: the Talos image enrolls its own keys in setup mode. | <pre>object({<br/>    bios              = optional(string, "seabios")<br/>    efi_datastore_id  = optional(string)<br/>    pre_enrolled_keys = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_machine"></a> [machine](#input\_machine) | Machine type: q35 (PCIe, needed for UEFI and TPM) or pc (i440fx). | `string` | `"q35"` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in MiB. floating\_mb is the balloon minimum: keep 0 to disable ballooning, because Talos does not handle memory hotplug. | <pre>object({<br/>    dedicated_mb = optional(number, 2048)<br/>    floating_mb  = optional(number, 0)<br/>  })</pre> | `{}` | no |
| <a name="input_on_boot"></a> [on\_boot](#input\_on\_boot) | Start the VM when the Proxmox node boots. | `bool` | `true` | no |
| <a name="input_operating_system_type"></a> [operating\_system\_type](#input\_operating\_system\_type) | Guest operating system type for Proxmox tuning. l26 is Linux 2.6 and later. | `string` | `"l26"` | no |
| <a name="input_pool_id"></a> [pool\_id](#input\_pool\_id) | ID of the Proxmox resource pool that holds the VM. Null puts no pool. Required when the API token only has rights on a pool. | `string` | `null` | no |
| <a name="input_scsi_hardware"></a> [scsi\_hardware](#input\_scsi\_hardware) | SCSI controller. virtio-scsi-pci is the Talos recommendation for Proxmox (virtio-scsi-single blocks the bootstrap, see siderolabs/talos#11173). Disk iothread needs virtio-scsi-single. | `string` | `"virtio-scsi-pci"` | no |
| <a name="input_started"></a> [started](#input\_started) | Start the VM after creation. | `bool` | `true` | no |
| <a name="input_stop_on_destroy"></a> [stop\_on\_destroy](#input\_stop\_on\_destroy) | Power the VM off on destroy instead of asking the guest to shut down. A Talos node is rebuilt from its configuration, so waiting for a graceful shutdown gains nothing. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Proxmox tags of the VM. | `list(string)` | `[]` | no |
| <a name="input_tpm"></a> [tpm](#input\_tpm) | Add a virtual TPM. Null adds none. Talos can seal disk encryption keys in the TPM, which needs SecureBoot (firmware.bios = ovmf). datastore\_id null uses the datastore of the first disk. | <pre>object({<br/>    datastore_id = optional(string)<br/>    version      = optional(string, "v2.0")<br/>  })</pre> | `null` | no |
| <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id) | Proxmox VM ID. Null lets Proxmox pick the next free ID. Set it when permissions or backups are bound to the ID. | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ipv4_addresses"></a> [ipv4\_addresses](#output\_ipv4\_addresses) | IPv4 addresses reported by the QEMU guest agent. Empty until the guest agent answers. |
| <a name="output_mac_addresses"></a> [mac\_addresses](#output\_mac\_addresses) | MAC addresses of the network devices. |
| <a name="output_name"></a> [name](#output\_name) | VM name, which is also the hostname Talos takes from cloud-init. |
| <a name="output_node_name"></a> [node\_name](#output\_node\_name) | Name of the Proxmox node that runs the VM. |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | Proxmox VM ID. |
<!-- END_TF_DOCS -->
