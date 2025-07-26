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

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    loginUser        = "devops"
    public_key_robin = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key  = indent(4, tls_private_key.host.private_key_openssh)
    server_name      = var.server_name
    dns_zone         = var.dns_zone
  })
  filename = "gen/userData.yml"
}

resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "dns_a_record_set" "server_a" {
  zone      = "${var.dns_zone}."
  name      = var.server_name
  addresses = [hcloud_server.debian_server.ipv4_address]
  ttl       = 10
}

module "ssh_wrapper" {
  source     = "../../modules/ssh-wrapper"
  loginUser  = "devops"
  hostname   = "${var.server_name}.${var.dns_zone}"
  public_key = tls_private_key.host.public_key_openssh
  depends_on = [dns_a_record_set.server_a]
}
