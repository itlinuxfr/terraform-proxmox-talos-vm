# A Talos node created from a disk image: no ISO, no CD-ROM, no install step.
# The image comes from terraform-proxmox-download-file with content_type = "import".
# The disk must be at least as large as the image.

terraform {
  required_version = ">= 1.15"
}

module "node" {
  source = "../../"

  node_name = "pve-01"
  name      = "talos-worker-2"

  disks = {
    scsi0 = {
      datastore_id = "local-zfs"
      size_gb      = 40
      import_from  = "local:import/talos-v1.14.6-nocloud-amd64.qcow2"
    }
  }
  network_devices = [{ bridge = "vmbr0" }]

  cloud_init = {
    datastore_id = "local-zfs"
    ip_configs   = [{ ipv4 = { address = "dhcp" } }]
  }
}
