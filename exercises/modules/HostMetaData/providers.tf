terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
  required_version = ">= 0.13"
}

# Configure the Hetzner Cloud API token
provider "hcloud" {
  token = var.hcloud_token
}
