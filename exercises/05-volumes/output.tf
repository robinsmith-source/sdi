output "hello_ip_addr" {
  value       = hcloud_server.helloServer.ipv4_address
  description = "The server's IPv4 address"
}

output "hello_datacenter" {
  value       = hcloud_server.helloServer.datacenter
  description = "The server's datacenter"
}

output "volume_id" {
  value       = hcloud_volume.volume01.id
  description = "The volume's id"
}
