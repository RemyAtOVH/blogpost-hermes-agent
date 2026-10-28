variable "ovh_endpoint" {
  description = "OVHcloud API endpoint: ovh-eu, ovh-ca, ovh-us…"
  type        = string
  default     = "ovh-eu"
}

variable "service_name" {
  description = "Public Cloud project id (the service_name)."
  type        = string
}

variable "region" {
  description = "Region code, e.g. GRA11, SBG5, DE1, UK1…"
  type        = string
  default     = "GRA11"
}

variable "instance_name" {
  description = "Instance name."
  type        = string
  default     = "hermes-agent"
}

variable "flavor_name" {
  description = "Commercial flavor name, resolved from the project catalog. b3-8 fits an agent (Python + Node + ffmpeg) comfortably."
  type        = string
  default     = "b3-8"
}

variable "image_name" {
  description = "Image name, resolved from the project catalog."
  type        = string
  default     = "Debian 13"
}

variable "power_state" {
  description = "ACTIVE (running), SHUTOFF (stopped), or SHELVED (off + released from the hypervisor — storage billed only)."
  type        = string
  default     = "ACTIVE"

  validation {
    condition     = contains(["ACTIVE", "SHUTOFF", "SHELVED"], var.power_state)
    error_message = "power_state must be ACTIVE, SHUTOFF or SHELVED."
  }
}

variable "public_ssh_key" {
  description = "Public SSH key injected into the instance (ed25519 recommended)."
  type        = string
}
