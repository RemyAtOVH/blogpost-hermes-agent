# Disposable prototype: a Public Cloud instance, billed by the hour.
# Create it, test it, shelve it, destroy it. Pair it with ../deploy.sh.
# Docs: https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_instance

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

# Resolve the flavor by its commercial name (b3-8, c3-4, …)
data "ovh_cloud_instance_flavors" "catalog" {
  service_name = var.service_name
  region       = var.region
}

# Resolve the image by its name (Debian 13, Debian 12, …)
data "ovh_cloud_instance_images" "catalog" {
  service_name = var.service_name
  region       = var.region
}

# Your SSH key, registered in the project and injected into the instance.
resource "ovh_cloud_ssh_key" "hermes" {
  service_name = var.service_name
  name         = "hermes-agent-key"
  public_key   = var.public_ssh_key
}

resource "ovh_cloud_instance" "hermes" {
  service_name = var.service_name
  region       = var.region
  name         = var.instance_name

  flavor_id = one([
    for flavor in data.ovh_cloud_instance_flavors.catalog.flavors :
    flavor.id if flavor.name == var.flavor_name
  ])

  image_id = one([
    for image in data.ovh_cloud_instance_images.catalog.images :
    image.id if image.name == var.image_name && lower(image.status) == "active"
  ])

  ssh_key_name = ovh_cloud_ssh_key.hermes.name

  networks = [
    { auto_assign_public_ip = true },
  ]

  # Pause the prototype:  terraform apply -var="power_state=SHELVED"
  # (released from the hypervisor — storage billed only; ACTIVE resumes in place)
  power_state = var.power_state
}
