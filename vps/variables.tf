variable "ovh_endpoint" {
  description = "OVHcloud API endpoint: ovh-eu, ovh-ca, ovh-us…"
  type        = string
  default     = "ovh-eu"
}

variable "vps_display_name" {
  description = "Display name of the VPS."
  type        = string
  default     = "hermes-agent"
}

variable "vps_plan_code" {
  description = "Plan code from the VPS catalog (GET /order/catalog/public/vps). Default: VPS-1 (2 vCores, 4 GB RAM, 40 GB NVMe)."
  type        = string
  default     = "vps-2027-model1"
}

variable "vps_datacenter" {
  description = "Datacenter code: GRA, SBG, WAW, DE… (pick an EU one for the sovereignty story)."
  type        = string
  default     = "WAW"
}

variable "vps_os" {
  description = "OS installed at provisioning."
  type        = string
  default     = "Debian 13"
}

variable "vps_image_id" {
  description = <<-EOT
    Image UUID — required when public_ssh_key is set: after the order, the provider
    rebuilds the VPS with this image + your key. Must match vps_os. Default: the
    Debian 13 image used in the provider's docs and acceptance tests. If apply fails
    at the rebuild step, the VPS already exists (and is in state): pick the Debian 13
    id from GET /vps/{serviceName}/images/available, set it, and re-apply.
  EOT
  type        = string
  default     = "45b2f222-ab10-44ed-863f-720942762b6f"
}

variable "public_ssh_key" {
  description = "Public SSH key injected into the VPS (ed25519 recommended)."
  type        = string
}
