resource "tls_private_key" "host" {
  algorithm = "ED25519"
}

# Generate an SSH key pair for server authentication
resource "hcloud_ssh_key" "user_ssh_key" {
  name       = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Generate a web access firewall to allow SSH, HTTP, and HTTPS traffic
resource "hcloud_firewall" "web_access_firewall" {
  name = "web-access-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Create a Debian server instance
resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    loginUser        = var.login_user
    public_key_robin = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key  = indent(4, tls_private_key.host.private_key_openssh)
  })
  filename = "gen/userData.yml"
}

# Create SSH wrapper for easier server access
module "ssh_wrapper" {
  source      = "../../modules/ssh-wrapper"
  loginUser   = var.login_user
  ipv4Address = hcloud_server.debian_server.ipv4_address
  public_key  = file("~/.ssh/id_ed25519.pub")
}
