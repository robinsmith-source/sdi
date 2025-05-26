output "hello_ip_addr" {
  value       = hcloud_server.newServer.ipv4_address
  description = "The server's IPv4 address"
}

output "hello_datacenter" {
  value       = hcloud_server.newServer.datacenter
  description = "The server's datacenter"
}
