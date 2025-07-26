output "server_ip" {
  value = hcloud_server.debian_server.ipv4_address
}

output "certificate_pem" {
  value = acme_certificate.certificate.certificate_pem
}

output "private_key_pem" {
  value = acme_certificate.certificate.private_key_pem
}
