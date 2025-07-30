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
  count = length(var.server_aliases)
  zone  = "${var.dns_zone}."
  name  = var.server_aliases[count.index]
  cname = "${var.server_name}.${var.dns_zone}."
  ttl   = 10
}