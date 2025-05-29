# Define Hetzner cloud provider and required version
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

# Configure Hetzner Cloud provider with API token
provider "hcloud" {
  token = var.hcloud_token
}

# Add SSH public key for server authentication
resource "hcloud_ssh_key" "user_ssh_key" {
  name       = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Create firewall rule to allow SSH access
resource "hcloud_firewall" "ssh_firewall" {
  name = "ssh-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Create a Debian server instance in Helsinki
resource "hcloud_server" "debian_server" {
  location     = "hel1"
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.ssh_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
}

# Create SSH wrapper for easier server access
module "ssh_wrapper" {
  source      = "../modules/ssh-wrapper"
  loginUser   = "root"
  ipv4Address = hcloud_server.debian_server.ipv4_address
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Generate host metadata for the server
module "host_metadata" {
  source      = "../modules/host-metadata"
  name        = hcloud_server.debian_server.name
  location    = hcloud_server.debian_server.location
  ipv4Address = hcloud_server.debian_server.ipv4_address
  ipv6Address = hcloud_server.debian_server.ipv6_address
}
