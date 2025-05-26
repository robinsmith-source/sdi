resource "hcloud_ssh_key" "loginRobin" {
  name = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_server" "newServer" {
  name        = var.name
  image       = "debian-12"
  server_type = "cx22"
  ssh_keys = [hcloud_ssh_key.loginRobin.id]
  user_data   = local_file.user_data.content
}

resource "tls_private_key" "hostKey" {
  algorithm = "ED25519"
}

resource "local_file" "hostdata" {
  content = templatefile("${path.module}/tpl/hostData.json", {
    ip4      = hcloud_server.newServer.ipv4_address
    ip6      = hcloud_server.newServer.ipv6_address
    location = hcloud_server.newServer.location
  })
  filename = "gen/${var.name}.json"
}

resource "local_file" "known_hosts_entry" {
  content         = "${hcloud_server.newServer.ipv4_address} ${tls_private_key.hostKey.public_key_fingerprint_sha256}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh_helper.sh", {
    ip   = hcloud_server.newServer.ipv4_address
    user = "devops"
  })
  filename        = "bin/ssh_${var.name}.sh"
  file_permission = "700"
  depends_on = [local_file.known_hosts_entry]
}

/*resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp_helper.sh", {
    ip   = hcloud_server.newServer.ipv4_address
    user = "devops"
  })
  filename        = "bin/scp_${var.name}.sh"
  file_permission = "700"
  depends_on = [local_file.known_hosts_entry]
}*/

resource "local_file" "user_data" {
  content = templatefile("${path.module}/tpl/userData.yml", {
    public_key_robin = hcloud_ssh_key.loginRobin.public_key
    tls_private_key = indent(4, tls_private_key.hostKey.private_key_openssh)
    tls_public_key   = tls_private_key.hostKey.public_key_openssh
    loginUser        = "devops"
  })
  filename = "gen/userData.yml"
}
