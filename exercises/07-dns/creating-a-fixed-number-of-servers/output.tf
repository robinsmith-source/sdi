output "server_ips" {
  value = hcloud_server.debian_server.*.ipv4_address
}
