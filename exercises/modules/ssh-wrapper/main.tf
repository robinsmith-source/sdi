resource "local_file" "known_hosts" {
  content         = "${var.ipv4Address} = ${var.public_key}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

# Generate SSH wrapper script from template
resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh.sh", {
    ip   = var.ipv4Address
    user = var.loginUser
  })
  filename        = "bin/ssh"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}

# Generate SCP wrapper script from template
resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp.sh", {
    ip   = var.ipv4Address,
    user = var.loginUser
  })
  filename        = "bin/scp"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}