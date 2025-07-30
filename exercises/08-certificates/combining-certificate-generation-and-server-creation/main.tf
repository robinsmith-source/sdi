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
    login_user          = "devops"
    public_key_robin    = hcloud_ssh_key.user_ssh_key.public_key
    server_names_string = join(" ", concat([var.dns_zone], [for name in var.server_names : "${name}.${var.dns_zone}"]))
    dns_zone            = var.dns_zone
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

resource "dns_a_record_set" "root_domain" {
  zone      = "${var.dns_zone}."
  addresses = [hcloud_server.debian_server.ipv4_address]
  ttl       = 10
}

resource "dns_cname_record" "aliases" {
  count = length(var.server_names)
  zone  = "${var.dns_zone}."
  name  = var.server_names[count.index]
  cname = "${var.dns_zone}."
  ttl   = 10
}
