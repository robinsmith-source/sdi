locals {
  target_host = var.hostname != null ? var.hostname : var.ipv4Address
}

resource "local_file" "known_hosts" {
  content         = "${local.target_host} ${var.public_key}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

# Generate SSH wrapper script from template
resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh.sh", {
    host = local.target_host
    user = var.loginUser
  })
  filename        = "bin/ssh"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}

# Generate SCP wrapper script from template
resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp.sh", {
    host = local.target_host,
    user = var.loginUser
  })
  filename        = "bin/scp"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}