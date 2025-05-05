# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
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
resource "hcloud_server" "helloServer" {
  name         = "hello"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.sshFw.id]
  ssh_keys     = [hcloud_ssh_key.loginRobin.id]
  user_data    = file("cloud-init.yaml")
}

resource "local_file" "known_hosts" {
  content         = "${hcloud_server.helloServer.ipv4_address}  ${tls_private_key.host.public_key_openssh}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh.sh", {
    ip = hcloud_server.hello.ipv4_address
  })
  filename        = "bin/ssh"
  file_permission = "700"
  depends_on      = [local_file.known_hosts]
}
