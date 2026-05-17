terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.106.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

locals {
  talos_version = "v1.13.2"
  schematic_id  = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
}

variable "proxmox_url" {
  type    = string
  default = "https://<changeme>:8006/"
}

variable "proxmox_api_key" {
  type    = string
  default = "<changeme>"
}

variable "target_node" {
  type    = string
  default = "pve"
}

variable "iso_storage" {
  type    = string
  default = "local"
}

variable "vm_storage" {
  type    = string
  default = "local-lvm-big"
}

provider "proxmox" {
  endpoint  = var.proxmox_url
  api_token = var.proxmox_api_key
  insecure  = true
}

provider "talos" {}
