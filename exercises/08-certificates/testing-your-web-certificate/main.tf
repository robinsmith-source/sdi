resource "tls_private_key" "host" {
  algorithm = "RSA"
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

resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    login_user          = "root"
    public_key_robin    = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key     = indent(4, tls_private_key.host.private_key_openssh)
    server_names_string = join(" ", [for name in var.server_names : "${name}.${var.dns_zone}"])
    dns_zone            = var.dns_zone
    certificate_pem     = indent(6, acme_certificate.certificate.certificate_pem)
    private_key_pem     = indent(6, acme_certificate.certificate.private_key_pem)
  })
  filename = "gen/userData.yml"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.host.private_key_pem
  email_address   = var.email_address
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "*.${var.dns_zone}"
  subject_alternative_names = [
    var.dns_zone,
  ]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = var.name_server
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "g10.key."
      RFC2136_TSIG_SECRET    = var.dns_secret
    }
  }
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
