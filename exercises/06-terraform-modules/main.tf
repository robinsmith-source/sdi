terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "login-user" {
  name       = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_firewall" "firewall-ssh" {
  name = "firewall-ssh"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "server" {
  location     = "hel1"
  name         = "my-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.firewall-ssh.id]
  ssh_keys     = [hcloud_ssh_key.login-user.id]
}


module "createSshWrappers" {
  source      = "../modules/ssh-wrapper"
  loginUser   = "root"
  ipv4Address = hcloud_server.server.ipv4_address
  public_key = file("~/.ssh/id_ed25519.pub")
}

module "createSshWrappers" {
  source      = "../modules/host-metadata"
  name        = hcloud_server.server.name
  location    = hcloud_server.server.location
  ipv4Address = hcloud_server.server.ipv4_address
  ipv6Address = hcloud_server.server.ipv6_address
}
