# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

resource "tls_private_key" "host" {
  algorithm = "ED25519"
}

resource "hcloud_firewall" "web_access_firewall" {
  name = "web-access-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_ssh_key" "user_ssh_key" {
  name       = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Create a server
resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "local_file" "known_hosts" {
  content         = "${hcloud_server.debian_server.ipv4_address} ${tls_private_key.host.public_key_fingerprint_sha256}"
  filename        = "gen/known_hosts_for_server"
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh_helper.sh", {
    ip = hcloud_server.debian_server.ipv4_address
    user = "devops"
  })
  filename        = "bin/ssh"
  file_permission = "700"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    loginUser     = "devops"
    public_key_robin    = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key = indent(4, tls_private_key.host.private_key_openssh)
  })
  filename = "gen/userData.yml"
}
