resource "hcloud_server" "newServer" {
  name        = var.name
  image       = "debian-12"
  server_type = "cx22"
}

resource "local_file" "hostdata" {
  content = templatefile("${path.module}/tpl/hostData.json", {
    ip4      = hcloud_server.newServer.ipv4_address
    ip6      = hcloud_server.newServer.ipv6_address
    location = hcloud_server.newServer.location
  })
  filename = "gen/${var.name}.json"
}
