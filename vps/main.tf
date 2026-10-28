# Provision an always-on VPS for Hermes Agent.
# Provider docs: https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/vps

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.20"
    }
  }
}

provider "ovh" {
  # Credentials are read from the environment:
  #   OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
  # Create them at https://www.ovh.com/auth/api/createToken
  endpoint = var.ovh_endpoint
}

# Country of the OVHcloud legal entity you'll be billed by.
data "ovh_me" "account" {}

resource "ovh_vps" "hermes" {
  display_name   = var.vps_display_name
  ovh_subsidiary = data.ovh_me.account.ovh_subsidiary

  # Required when public_ssh_key is set. Available image UUIDs:
  # https://eu.api.ovh.com/console/?section=/vps&branch=v1#get-/vps/-serviceName-/images/available
  image_id = var.vps_image_id

  plan = [
    {
      duration     = "P1M"
      plan_code    = var.vps_plan_code
      pricing_mode = "default"

      configuration = [
        {
          label = "vps_datacenter"
          value = var.vps_datacenter
        },
        {
          label = "vps_os"
          value = var.vps_os
        },
      ]
    }
  ]

  public_ssh_key = var.public_ssh_key

  # Note: ordering via the API requires a default payment method on the account.
}

# The ovh_vps resource does not export IPs — fetch them through the data source.
data "ovh_vps" "hermes" {
  service_name = ovh_vps.hermes.name
}
