terraform {
  # 1.15 adds explicit type constraints on outputs, used in outputs.tf.
  required_version = ">= 1.15"

  # A module declares a lower bound only: the live repository pins exact versions.
  # 0.100.0 matches terraform-proxmox-download-file, the module that provides the boot image or the disk image.
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.100.0"
    }
  }
}
