locals {
  cluster_name = "talos-lab"

  cp_ip      = try([for ip in flatten(proxmox_virtual_environment_vm.talos_cp.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "0.0.0.0")
  worker_ips = [for vm in proxmox_virtual_environment_vm.talos_workers : try([for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "0.0.0.0")]
}

resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = local.cluster_name
  cluster_endpoint = "https://${local.cp_ip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = local.talos_version
}

data "talos_machine_configuration" "worker" {
  cluster_name     = local.cluster_name
  cluster_endpoint = "https://${local.cp_ip}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = local.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.cp_ip]
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = local.cp_ip
  endpoint                    = local.cp_ip

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = "/dev/sda"
          image = "factory.talos.dev/installer/${local.schematic_id}:${local.talos_version}"
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "workers" {
  count                       = length(local.worker_ips)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = local.worker_ips[count.index]
  endpoint                    = local.worker_ips[count.index]

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = "/dev/sda"
          image = "factory.talos.dev/installer/${local.schematic_id}:${local.talos_version}"
        }
      }
    })
  ]
}

resource "time_sleep" "wait_for_reboot" {
  depends_on      = [talos_machine_configuration_apply.controlplane]
  create_duration = "120s"
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [time_sleep.wait_for_reboot]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_ip
  endpoint             = local.cp_ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_ip
  endpoint             = local.cp_ip
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/kubeconfig"
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/talosconfig"
}

output "detected_cp_ip" {
  value = local.cp_ip
}

output "detected_worker_ips" {
  value = local.worker_ips
}
