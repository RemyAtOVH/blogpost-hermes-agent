locals {
  all_addrs = flatten([
    for n in try(ovh_cloud_instance.hermes.current_state.networks, []) :
    try(n.addresses, [])
  ])
  ipv4 = [for a in local.all_addrs : a.ip if try(a.version, 0) == 4]
}

output "instance_ip" {
  description = "IPv4 address of the instance — run: ./deploy.sh debian@<instance_ip>"
  value       = length(local.ipv4) > 0 ? local.ipv4[0] : null
}
