locals {
  target_host = var.hostname != null && var.hostname != "" ? var.hostname : var.ipv4Address
}

resource "local_file" "known_hosts" {
  content         = "${local.target_host} ${var.public_key}"
  filename        = "gen/known_hosts_${local.target_host}"
  file_permission = "644"
}

# Generate SSH wrapper script from template
resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh.sh", {
    host = local.target_host
    user = var.login_user
  })
  filename        = "bin/ssh_${local.target_host}"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}

# Generate SCP wrapper script from template
resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp.sh", {
    host = local.target_host,
    user = var.login_user
  })
  filename        = "bin/scp_${local.target_host}"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}