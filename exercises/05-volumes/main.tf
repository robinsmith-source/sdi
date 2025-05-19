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

resource "hcloud_firewall" "sshFw" {
  name = "ssh-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_ssh_key" "loginRobin" {
  name       = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Create a server
resource "hcloud_server" "basicServer" {
  name         = "hello"
  image        = "debian-12"
  server_type  = "cx22"
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.sshFw.id]
  ssh_keys     = [hcloud_ssh_key.loginRobin.id]
  user_data    = local_file.user_data.content
}

resource "hcloud_volume" "volume01" {
  name      = "volume01"
  location  = "nbg1"
  size      = 10
  automount = false
  format    = "xfs"
}

resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.volume01.id
  server_id = hcloud_server.basicServer.id
}

resource "local_file" "known_hosts_entry" {
  content         = "${hcloud_server.basicServer.ipv4_address} ${tls_private_key.host.public_key_fingerprint_sha256}"
  filename        = "gen/known_hosts_for_server"
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh_helper.sh", {
    ip   = hcloud_server.basicServer.ipv4_address
    user = "devops"
  })
  filename        = "bin/ssh"
  file_permission = "700"
  depends_on      = [local_file.known_hosts_entry]
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    public_key_robin = hcloud_ssh_key.loginRobin.public_key
    tls_private_key  = indent(4, tls_private_key.host.private_key_openssh)
    tls_public_key   = tls_private_key.host.public_key_openssh
    loginUser        = "devops"
    volId = hcloud_volume.volume01.id
  })
  filename = "gen/userData.yml"
}
