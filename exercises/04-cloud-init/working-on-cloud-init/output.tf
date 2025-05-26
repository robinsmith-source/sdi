output "hello_ip_addr" {
  value       = hcloud_server.basicServer.ipv4_address
  description = "The server's IPv4 address"
}

output "hello_datacenter" {
  value       = hcloud_server.basicServer.datacenter
  description = "The server's datacenter"
}
