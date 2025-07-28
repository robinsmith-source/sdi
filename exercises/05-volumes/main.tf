resource "tls_private_key" "host" {
  algorithm = "ED25519"
}

resource "hcloud_firewall" "ssh_firewall" {
  name = "ssh-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
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
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.ssh_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "hcloud_volume" "data_volume" {
  name      = "data-volume"
  location  = "nbg1"
  size      = 10
  automount = false
  format    = "xfs"
}

resource "hcloud_volume_attachment" "volume_attachment" {
  volume_id = hcloud_volume.data_volume.id
  server_id = hcloud_server.debian_server.id
}

resource "local_file" "known_hosts" {
  content         = "${hcloud_server.debian_server.ipv4_address} ${tls_private_key.host.public_key_fingerprint_sha256}"
  filename        = "gen/known_hosts_for_server"
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh_helper.sh", {
    host   = hcloud_server.debian_server.ipv4_address
    user = var.login_user
  })
  filename        = "bin/ssh"
  file_permission = "700"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    public_key      = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key = indent(4, tls_private_key.host.private_key_openssh)
    tls_public_key  = tls_private_key.host.public_key_openssh
    loginUser       = var.login_user
    volId           = hcloud_volume.data_volume.id
  })
  filename = "gen/userData.yml"
}
