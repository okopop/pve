locals {
  cp_mac      = "BC:24:11:00:00:01"
  worker_macs = ["BC:24:11:00:00:11", "BC:24:11:00:00:12"]
}

# Control Plane Node
resource "proxmox_virtual_environment_vm" "talos_cp" {
  name            = "talos-cp-01"
  node_name       = var.target_node
  vm_id           = 800
  stop_on_destroy = true
  tags            = ["k8s"]

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
    timeout = "5m"
    wait_for_ip {
      ipv4 = true
    }
  }

  # KORRIGERING: Parametern heter scsi_hardware
  scsi_hardware = "virtio-scsi-single"

  network_device {
    bridge      = "vmbr0"
    mac_address = local.cp_mac
    firewall    = false
    model       = "virtio"
  }

  disk {
    datastore_id = var.vm_storage
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  cdrom {
    file_id = "${var.iso_storage}:iso/talos-${local.talos_version}.iso"
  }

  operating_system {
    type = "l26"
  }
}

# Worker Nodes
resource "proxmox_virtual_environment_vm" "talos_workers" {
  count           = 2
  name            = "talos-worker-0${count.index + 1}"
  node_name       = var.target_node
  vm_id           = 801 + count.index
  stop_on_destroy = true
  tags            = ["k8s"]

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
    timeout = "5m"
    wait_for_ip {
      ipv4 = true
    }
  }

  # KORRIGERING: Parametern heter scsi_hardware
  scsi_hardware = "virtio-scsi-single"

  network_device {
    bridge      = "vmbr0"
    mac_address = local.worker_macs[count.index]
    firewall    = false
    model       = "virtio"
  }

  disk {
    datastore_id = var.vm_storage
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  cdrom {
    file_id = "${var.iso_storage}:iso/talos-${local.talos_version}.iso"
  }

  operating_system {
    type = "l26"
  }
}
