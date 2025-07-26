output "certificate_pem" {
  value     = acme_certificate.certificate.certificate_pem
  sensitive = true
}

output "private_key_pem" {
  value     = acme_certificate.certificate.private_key_pem
  sensitive = true
}
