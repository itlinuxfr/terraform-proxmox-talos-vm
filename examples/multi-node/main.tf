# One Talos control-plane node on each node of a Proxmox cluster: for_each on the module call, with the Proxmox node in the map.
#
# In a Proxmox cluster:
# - A VM ID must be unique in the whole cluster, not only on its node.
# - A datastore that is local to each node (local-zfs) has its own files: download the ISO once per node
#   (terraform-proxmox-download-file takes a node_name). A shared datastore needs a single download.
# - An SDN VNet belongs to the whole zone, so the bridge name is the same on every node.

terraform {
  required_version = ">= 1.15"
}

locals {
  cluster_cidr = "192.0.2.0/27"
  gateway      = cidrhost(local.cluster_cidr, 1)
  prefix       = split("/", local.cluster_cidr)[1]

  nodes = {
    "talos-cp-1" = { proxmox_node = "pve-01", vm_id = 7001, host = 3 }
    "talos-cp-2" = { proxmox_node = "pve-02", vm_id = 7002, host = 4 }
    "talos-cp-3" = { proxmox_node = "pve-03", vm_id = 7003, host = 5 }
  }
}

module "node" {
  source   = "../../"
  for_each = local.nodes

  node_name = each.value.proxmox_node
  name      = each.key
  vm_id     = each.value.vm_id
  tags      = ["talos", "controlplane"]

  disks           = { scsi0 = { datastore_id = "local-zfs", size_gb = 20 } }
  network_devices = [{ bridge = "vmbr0" }]
  cdrom           = { file_id = "local:iso/talos-v1.14.6-nocloud-amd64.iso" }

  cloud_init = {
    datastore_id = "local-zfs"
    ip_configs   = [{ ipv4 = { address = "${cidrhost(local.cluster_cidr, each.value.host)}/${local.prefix}", gateway = local.gateway } }]
    dns          = { servers = ["192.0.2.53"] }
  }
}

# The Proxmox node of each VM, for example for the topology.kubernetes.io/zone label that proxmox-csi-plugin needs.
output "zone_by_node" {
  value = { for name, vm in module.node : name => vm.node_name }
}
