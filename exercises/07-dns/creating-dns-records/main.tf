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
  })
  filename = "gen/userData.yml"
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

# A record for the server's canonical name (e.g., workhorse.g10.sdi.hdm-stuttgart.cloud)
resource "dns_a_record_set" "server_a" {
  zone      = "${var.dns_zone}."
  name      = var.server_name
  addresses = [var.server_ip]
  ttl       = 10
}

# A record for the root domain (e.g., g10.sdi.hdm-stuttgart.cloud)
resource "dns_a_record_set" "server_a_root" {
  zone      = "${var.dns_zone}."
  addresses = [var.server_ip]
  ttl       = 10
}

# CNAME records for server aliases using count meta-argument
resource "dns_cname_record" "server_aliases" {
  count      = length(var.server_aliases)
  zone       = "${var.dns_zone}."
  name       = var.server_aliases[count.index]
  cname      = "${var.server_name}.${var.dns_zone}."
  ttl        = 300
  depends_on = [dns_a_record_set.server_a, hcloud_server.debian_server]
}

module "ssh_wrapper" {
  source     = "../../modules/ssh-wrapper"
  loginUser  = "devops"
  hostname   = "${var.server_name}.${var.dns_zone}"
  public_key = tls_private_key.host.public_key_openssh
  depends_on = [dns_a_record_set.server_a]
}
