# Server Initialization

> This chapter builds on the previous one, focusing on server initialization and configuration using Terraform and Cloud-Init. It introduces automated server setup, security hardening, and the use of helper scripts for easier server management.

## Prerequisites

Before you begin, you should have a working Terraform project that can provision a server with an SSH key, as covered in the [Working with Terraform](/chapters/03-working-with-terraform) chapter.

## External Resources

For more in-depth information on the topics covered in this chapter:

- [Terraform: `templatefile` function](https://www.terraform.io/language/functions/templatefile) - Official documentation for Terraform's templating function.
- [Cloud-Init Module Reference](https://cloudinit.readthedocs.io/en/latest/reference/modules.html) - Detailed information on all available Cloud-Init modules.
- [sshd_config(5) - Linux man page](https://man7.org/linux/man-pages/man5/sshd_config.5.html) - Manual for the SSH daemon configuration file.

::: tip
For comprehensive information about Cloud-Init concepts, see [Cloud-Init Concepts](/knowledge/cloud-init).
:::

## 1. Automatic Nginx Installation with `user_data` [Exercise 12] {#exercise-12}

In this exercise, you will use a `user_data` field in Terraform to pass a bash script to your server. This script will automatically install, start, and enable the Nginx web server upon the server's first boot.

### 1.1 Creating the Initialization Script

First, create a shell script (e.g., `init.sh`) that contains the necessary commands.

::: code-group

```sh [init.sh]
#!/bin/bash

apt update && apt upgrade -y # Update package lists and upgrade existing packages
apt install -y nginx # Install the Nginx web server

systemctl start nginx # Start the Nginx service immediately
systemctl enable nginx # Enable Nginx to start automatically on future boots
```

:::

### 1.2 Configuring the Server Resource

Next, modify your `hcloud_server` resource in `main.tf` to execute this script on boot using the `user_data` attribute.

```hcl [main.tf]
resource "hcloud_server" "web_server" {
  name        = "web-server-bash"
  image       = "debian-12"
  server_type = "cx22"
  firewall_ids = [hcloud_firewall.ssh_firewall.id] // [!code --]
  firewall_ids = [hcloud_firewall.web_access_firewall.id] // [!code ++]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = file("init.sh") // [!code ++]
}
```

::: tip
You can test your script on an existing server before running `terraform apply`.
This can save time and avoid unnecessary create/destroy cycles.
:::

This will create a server with Nginx installed and running. To verify that the script is working as expected, you will need to configure a firewall rule for web traffic.

```hcl [main.tf]
resource "hcloud_firewall" "ssh_firewall" { // [!code --]
resource "hcloud_firewall" "web_access_firewall" { // [!code ++]
  name = "web-access-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule { // [!code ++:6]
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
```

After applying the changes, you can test the web server by pointing your web browser to `http://<YOUR_SERVER_IP>`. You should see a default Nginx page.

## 2. Working with Cloud-Init [Exercise 13] {#exercise-13}

In this multi-part exercise, you will incrementally build a robust server configuration using Cloud-Init. You will use the configuration from [Exercise 11](/chapters/03-working-with-terraform#_1-terraform-introduction-and-basic-configuration) as a starting point.

### 2.1 Creating a Simple Web Server

First, you'll have to extend the firewall to allow inbound traffic on `port 80`, like you did in [Exercise 12](/chapters/04-server-initialization#_1-automatic-nginx-installation-with-user_data-exercise-12).

```hcl [main.tf]
resource "hcloud_firewall" "ssh_firewall" { // [!code --]
resource "hcloud_firewall" "web_access_firewall" { // [!code ++]
  name = "web-access-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule { // [!code ++:6]
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
```

You will also have to extend the Terraform configuration to use the following cloud-init configuration.

::: code-group

```hcl [main.tf]
resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.ssh_firewall.id] // [!code --]
  firewall_ids = [hcloud_firewall.web_access_firewall.id] // [!code ++]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content // [!code ++]
}

resource "local_file" "user_data" { // [!code ++:9]
  content = templatefile("tpl/userData.yml", {
    login_user        = var.login_user
    public_key_robin = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key  = indent(4, tls_private_key.host.private_key_openssh)
  })
  filename = "gen/userData.yml"
}
```

```yml [tpl/userData.yml]
#cloud-config
users:
  - name: ${login_user}
    groups: [sudo]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${public_key_robin}

ssh_keys:
  ed25519_private: |
    ${tls_private_key}
ssh_pwauth: false
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
  - nginx
  - fail2ban
  - plocate
  - python3-systemd # Add python3-systemd for fail2ban backend

write_files:
  - path: /etc/fail2ban/jail.local
    content: |
      [DEFAULT]
      # Ban hosts for 1 hour:
      bantime = 1h

      # Override /etc/fail2ban/jail.d/defaults-debian.conf:
      backend = systemd

      [sshd]
      enabled = true
      # To use internal sshd filter variants

runcmd:
  # Existing Nginx setup
  - systemctl enable nginx
  - rm /var/www/html/*
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  - systemctl enable fail2ban
  - systemctl start fail2ban
  - updatedb
  - systemctl restart fail2ban
```

:::

On success, pointing your web browser to `http://<YOUR_SERVER_IP>` should result in a message similar to: `I'm Nginx @ "YOUR_SERVER_IP" created Sun May 5 06:58:37 PM UTC 2024`.

This complete `userData.yml` configuration includes:

- **User Management**: Creates a new user with sudo privileges and SSH key access
- **SSH Security**: Disables password authentication and root login
- **Package Management**: Updates and upgrades all packages, reboots if required
- **Web Server**: Installs and configures Nginx with a custom welcome page
- **Security**: Installs and configures Fail2Ban for intrusion detection

You can verify the setup by checking:

- `fail2ban-client status sshd` - for Fail2Ban status
- `journalctl -f` - for logs
- `apt list --upgradable` - should be empty after updates
- `systemctl status nginx` - for Nginx status

## 3. Generating Helper Scripts [Exercise 14] {#exercise-14}

In this exercise, you will use Terraform to generate `ssh` and `scp` helper scripts. This simplifies server access by pre-configuring the server's IP address and handling SSH host key verification automatically.

By generating a new SSH key pair with Terraform (`tls_private_key`), you can determine the server's public host key _before_ the server is even created. You then inject the private part of this key into the new server using `user_data`, and use the public part to create a `known_hosts` file locally. This way, your local SSH client will trust the server on the first connection, preventing the usual host key verification prompt.

### 3.1. Creating Script Templates

First, create templates for the `ssh` and `scp` scripts in a `tpl` directory. These are the same templates used in later chapters.

::: code-group

```sh [tpl/ssh.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${host} "$@"
```

```sh [tpl/scp.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

if [ $# -lt 2 ]; then
   echo usage: ./bin/scp <arguments>
else
   scp -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${host} $@
fi
```

:::

### 3.2. Generating Scripts with Terraform

Next, modify your `main.tf` to generate the final scripts from the templates, injecting the necessary values. You will also add a `login_user` variable for convenience.

The `known_hosts` file requires a specific format: `<ip_address> <key_type> <public_key>`. You will construct this using the server's IP and the public key from your `tls_private_key` resource.

::: code-group

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "tls_private_key" "host" { // [!code focus:36]
  algorithm = "ED25519"
}

resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "local_file" "known_hosts" { // [!code ++:5]
  content         = "${hcloud_server.debian_server.ipv4_address} ${tls_private_key.host.public_key_fingerprint_sha256}"
  filename        = "gen/known_hosts_for_server"
  file_permission = "644"
}

resource "local_file" "ssh_script" { // [!code ++:8]
  content = templatefile("/tpl/ssh.sh", {
    user = var.login_user,
    host = hcloud_server.debian_server.ipv4_address
  })
  filename        = "bin/ssh"
  file_permission = "755"
}

resource "local_file" "scp_script" { // [!code ++:8]
  content = templatefile("/tpl/scp.sh", {
    user = var.login_user,
    host = hcloud_server.debian_server.ipv4_address
  })
  filename        = "bin/scp"
  file_permission = "755"
}
```

```hcl [variables.tf]
variable "login_user" {
  description = "Login user for the server"
  type        = string
  nullable    = false
  default     = "devops"
}
```

:::

After executing `terraform apply`, you will have executable `ssh` and `scp` scripts in your local `bin` directory. Using these scripts (e.g., `./bin/ssh`) allows you to connect to your server without seeing the "REMOTE HOST IDENTIFICATION HAS CHANGED" warning, as the host key is already trusted.
