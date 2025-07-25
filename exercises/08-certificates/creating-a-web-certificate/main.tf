resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "nobody@example.com"
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "*.${var.dns_zone}"
  subject_alternative_names = [
    var.dns_zone,
    "www.${var.dns_zone}",
    "mail.${var.dns_zone}"
  ]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = "ns1.sdi.hdm-stuttgart.cloud"
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "g10.key."
      RFC2136_TSIG_SECRET    = var.dns_secret
    }
  }
}

resource "local_file" "private_key_pem" {
  content  = acme_certificate.certificate.private_key_pem
  filename = "gen/private.pem"
}

resource "local_file" "certificate_pem" {
  content  = acme_certificate.certificate.certificate_pem
  filename = "gen/certificate.pem"
}
