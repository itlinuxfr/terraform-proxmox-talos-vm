# A Talos control-plane node with SecureBoot (UEFI, no pre-enrolled keys) and a TPM 2.0, on a VLAN-aware bridge.
# Use a SecureBoot ISO: terraform-talos-image returns it in iso_url when secureboot.enabled is true.
# vm_id and pool_id are set because the Proxmox API token only has rights on this ID and this pool.

terraform {
  required_version = ">= 1.15"
}

module "node" {
  source = "../../"

  node_name = "pve-01"
  name      = "talos-cp-1"
  vm_id     = 7001
  pool_id   = "k8s-prod"
  tags      = ["talos", "controlplane"]

  firmware = { bios = "ovmf" }
  tpm      = {}

  disks           = { scsi0 = { datastore_id = "local-zfs", size_gb = 20 } }
  network_devices = [{ bridge = "vmbr0", vlan_id = 700 }]
  cdrom           = { file_id = "local:iso/talos-v1.14.6-nocloud-amd64-secureboot.iso" }

  cloud_init = {
    datastore_id = "local-zfs"
    ip_configs   = [{ ipv4 = { address = "192.0.2.3/27", gateway = "192.0.2.1" } }]
    dns          = { servers = ["192.0.2.53", "192.0.2.1"] }
  }
}
