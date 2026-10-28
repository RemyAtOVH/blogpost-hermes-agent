locals {
  all_ips = tolist(data.ovh_vps.hermes.ips)
  ipv4    = [for ip in local.all_ips : ip if can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", ip))]
}

output "vps_ip" {
  description = "IPv4 address of the VPS — run: ./deploy.sh debian@<vps_ip>"
  value       = length(local.ipv4) > 0 ? local.ipv4[0] : (length(local.all_ips) > 0 ? local.all_ips[0] : null)
}

output "vps_service_name" {
  description = "Service name of the VPS (e.g. vps-xxxxx.ovh.net)"
  value       = ovh_vps.hermes.name
}
