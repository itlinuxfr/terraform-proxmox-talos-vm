# A Talos node that boots from an ISO, with a static IP address from cloud-init.
# In a real project, pin the module source to a tag:
#   source = "git::https://github.com/itlinuxfr/terraform-proxmox-talos-vm.git?ref=v1.0.0"
# The relative source is used by CI: it tests the code of the current branch.
# The ISO comes from terraform-proxmox-download-file (its id output), built from a terraform-talos-image URL.

terraform {
  required_version = ">= 1.15"
}

module "node" {
  source = "../../"

  node_name = "pve-01"
  name      = "talos-worker-1"
  tags      = ["talos", "worker"]

  cpu    = { cores = 4 }
  memory = { dedicated_mb = 8192 }

  disks           = { scsi0 = { datastore_id = "local-zfs", size_gb = 40 } }
  network_devices = [{ bridge = "vmbr0" }]
  cdrom           = { file_id = "local:iso/talos-v1.14.6-nocloud-amd64.iso" }

  cloud_init = {
    datastore_id = "local-zfs"
    ip_configs   = [{ ipv4 = { address = "192.0.2.10/24", gateway = "192.0.2.1" } }]
    dns          = { servers = ["192.0.2.53"] }
  }
}

output "ipv4_addresses" {
  value = module.node.ipv4_addresses
}
