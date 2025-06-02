# Server Initialization Guide

> This guide provides an overview of server initialization methods using Terraform on Hetzner Cloud. It covers both basic `Bash` scripts and the more advanced Cloud-Init with Cloud-Config.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account
- A Hetzner Cloud API Token
- Terraform installed on your local machine

## External Resources

For more in-depth information about server initialization and cloud computing:

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/) - Official Cloud-Init documentation
- [Arch Wiki: Cloud-Init](https://wiki.archlinux.org/title/Cloud-init) - Cloud-Init setup and configuration
- [Arch Wiki: Systemd](https://wiki.archlinux.org/title/Systemd) - Systemd service management
- [Arch Wiki: Fail2ban](https://wiki.archlinux.org/title/Fail2ban) - Fail2ban security setup
- [Arch Wiki: Nginx](https://wiki.archlinux.org/title/Nginx) - Nginx web server configuration

## 1. Using Bash Init Scripts for Server Initialization

A straightforward approach to server initialization involves providing a `Bash` script that executes during the server's first boot.

This example demonstrates passing a `Bash` script via Terraform to update the server's packages:

::: code-group

```hcl [main.tf]
resource "hcloud_server" "debian_server" { 
  name        = "debian-server"
  image       = "debian-12"
  server_type = "cx22"
  user_data   = file("init.sh") // Specifies the path to the initialization script // [!code ++]
}
```

```sh [init.sh]
#!/bin/bash
# This script updates all packages on the server's first boot.
apt update && apt upgrade -y
```

:::

You can extend this script for more complex tasks, such as software installation. For instance, to install Nginx and set up a default webpage:

```sh [scripts/init-nginx.sh]
#!/bin/bash
# Update system packages
apt update && apt upgrade -y

# Install Nginx web server
apt install -y nginx # [!code ++]

# Create a simple default HTML page
echo "Hello from my Terraform server!" > /var/www/html/index.html # [!code ++]

# Start Nginx and enable it to start on boot
systemctl start nginx # [!code ++]
systemctl enable nginx  # [!code ++]
```

This script performs package updates, installs Nginx, starts the Nginx service, enables it for auto-start on boot, and creates a basic `index.html`, which is served on port 80 by default.

While Bash scripts are effective for simple initializations, managing intricate configurations, user setups, or extensive file manipulations can become complex. For these scenarios, Cloud-Init offers a more structured and powerful solution.

## 2. Cloud-Init: Installing Packages

To use Cloud-Init, create a cloud-config `YAML` file (e.g., `userData.yml`) and reference it in your Terraform configuration. The following example installs Nginx and generates a dynamic index page:

::: code-group

```hcl [main.tf]
# ... (ensure other necessary configurations like provider setup are present) ...

resource "hcloud_server" "debian_server" { // [!code focus:6]
  name        = "debian-server"
  image       = "debian-12"
  server_type = "cx22"
  user_data = file("tpl/userData.yml") // Reference the cloud-config YAML file // [!code ++]
}

# ... (rest of your Terraform configuration) ...
```

```yml [tpl/userData.yml]
#cloud-config
# Install the nginx package
packages:
  - nginx

# Commands to run after package installation
runcmd:
  # Ensure Nginx starts automatically on boot
  - systemctl enable nginx
  # Remove any default Nginx content
  - rm /var/www/html/*
  # Create a dynamic index page displaying the server's public IP and creation timestamp
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  # Restart SSH service (recommended if SSH configurations were modified by cloud-init)
  - systemctl restart sshd
```

:::

Upon server creation, Cloud-Init will execute the tasks defined in `tpl/userData.yml`. You can verify the Nginx installation by connecting to the server via SSH and checking its status (e.g., `systemctl status nginx`).

::: details **Firewall Configuration for Web Access**
Note that accessing the web server on port 80 requires a firewall rule. Here's how to configure it in Terraform:

```hcl {9-14}
resource "hcloud_firewall" "web_access_firewall" {
  name = "web-access-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22" // Keep SSH access
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80" // Allow HTTP traffic
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
```

Ensure your server is associated with this firewall. Otherwise you can also use ssh port forwarding like described [here](02-using-ssh.md#_4-ssh-port-forwarding).
:::

## 3. Cloud-Init: User Management and Templating

Cloud-Init excels at tasks like managing user accounts and SSH access. Furthermore, Terraform's templating capabilities allow you to dynamically inject variables (such as SSH public keys) into your cloud-config files.

Update your cloud-config template (`tpl/userData.yml`) to include user creation, SSH access restrictions, and variable usage:

:::code-group

```yml [tpl/userData.yml]
users: // [!code ++:17]
  - name: ${loginUser} # Username (e.g., "devops"), injected from Terraform 
    groups: sudo # Add user to the sudo group
    shell: /bin/bash # Set default shell
    sudo: ALL=(ALL) NOPASSWD:ALL # Grant sudo privileges without password prompt
    ssh_authorized_keys: # List of authorized public SSH keys
      - ${public_key_one} # First public key, injected from Terraform
      - ${public_key_two} # Second public key, injected from Terraform
      # Add more public keys as needed

ssh_keys:
  ed25519_private: |
    ${tls_private_key}
ssh_pwauth: false
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Install necessary packages (can be combined with other directives)
packages:
  - nginx

# Execute commands after users and files are set up
runcmd:
  # Existing Nginx setup
  - systemctl enable nginx
  - rm /var/www/html/*
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
```

:::

To process this template and inject the defined variables:

1.  Ensure your `userData.yml` template is located in a `tpl` (template) directory (e.g., `./tpl/userData.yml`).
2.  Define `hcloud_ssh_key` resources for your public keys in `main.tf`.
3.  Use a `local_file` data source in `main.tf` to render the template with variables:

::: code-group

```hcl [main.tf]
# ... (provider configuration and other resources) ...

# Example SSH key resources (replace with your actual key management) // [!code focus:21]
resource "hcloud_ssh_key" "user_ssh_key_one" {
  name       = "user-key-one"
  public_key = file("~/.ssh/id_ed25519.pub") // Path to your first public key
}

resource "hcloud_ssh_key" "user_ssh_key_two" {
  name       = "user-key-two"
  public_key = file("~/.ssh/another_key.pub") // Path to your second public key
}

# Render the cloud-init template with variables  // [!code ++:10]
resource "local_file" "user_data_rendered" {
  content = templatefile("tpl/userData.yml", {
    loginUser      = "devops"                             // Define the username to create
    public_key_one = indent(4, hcloud_ssh_key.user_ssh_key_one.public_key) // Pass the first public key
    public_key_two = indent(4, hcloud_ssh_key.user_ssh_key_two.public_key) // Pass the second public key
    # Add other variables as needed for your template
  })
  filename = "gen/userData.rendered.yml" // Output path for the processed template
}

# ... (other resources, including the hcloud_server resource) ...
```

:::

4.  Update your `hcloud_server` resource to use the content of the _rendered_ template:

::: code-group

```hcl [main.tf]
# ... (existing configuration) ...

resource "hcloud_server" "debian_server" { // [!code focus:7]
  name        = "debian-server"
  image       = "debian-12"
  server_type = "cx22"
  user_data   = local_file.user_data_rendered.content // Use the rendered template content // [!code ++]
}

# ... (rest of your Terraform configuration) ...
```

:::

Running `terraform apply` will now:

1.  Generate the `gen/userData.rendered.yml` file with your specified values substituted for the variables.
2.  Pass this rendered YAML content to the Hetzner Cloud server during its creation.

## 4. Securing Your Server with fail2ban

Fail2ban is a powerful tool that helps protect your server from brute-force attacks by monitoring log files and banning IPs that show malicious signs.

1. Installing fail2ban with Cloud-Init

Add the following to your `tpl/userData.yml` cloud-config file:

```yml
#cloud-config
packages:
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
  - systemctl enable fail2ban
  - systemctl start fail2ban
  - updatedb
  - systemctl restart fail2ban
```

Reference this file in your Terraform configuration as shown in previous sections.

2. Verifying fail2ban

After your server is initialized, verify fail2ban is running:

```sh
sudo systemctl status fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

You should see that the `sshd` jail is enabled and monitoring for failed login attempts.

3. Customizing fail2ban

- You can adjust the `bantime`, add more jails, or tweak filters in `/etc/fail2ban/jail.local`.
- For more information, see the [Arch Wiki: Fail2ban](https://wiki.archlinux.org/title/Fail2ban).

## 5. Handling SSH Host Key Mismatches

When a server is destroyed and recreated (even with the same IP address), it typically generates a new unique SSH host key. Your SSH client, upon attempting to connect, will detect this change and issue a warning about a potential "man-in-the-middle" (MITM) attack. This is because the new server's host key no longer matches the one stored in your local `~/.ssh/known_hosts` file for that IP address.

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```

While a comprehensive solution involves managing persistent host keys (e.g., generating them with Terraform and configuring the server via cloud-init to use them), a more straightforward method for managing development or frequently changing environments is to generate a specific `known_hosts` file using Terraform and employ a helper script for SSH connections.

**Steps to Mitigate Host Key Warnings with a Helper Script:**

1.  **Generate a `known_hosts` Entry with Terraform:**
    Create a `local_file` resource that stores the server's IP address and its expected public host key.
    _(Important Note: This approach is most effective if you manage the server's host key via Terraform, for example, using `tls_private_key`. If the server generates its own host key ephemerally on each boot, this method alone won't prevent the warning without a more advanced cloud-init setup to install the pre-generated key on the server.)_

::: code-group

```hcl [main.tf]
# Example: Assume tls_private_key.host_key manages the server's host key pair
resource "tls_private_key" "host_key" {
  algorithm = "ED25519" // Recommended algorithm
}

# Generate a known_hosts file entry for the server
resource "local_file" "known_hosts" {
  content  = "${hcloud_server.debian_server.ipv4_address} ${tls_private_key.host_key.public_key_openssh}"
  filename = "gen/known_hosts_for_server" // Descriptive filename in the 'gen' directory
  file_permission = "644" // Set read-write permissions
}
```

:::

2.  **Create an SSH Helper Script Template:**
    Develop a script template (`tpl/ssh_helper.sh`) that instructs the SSH client to use your generated `known_hosts` file.

::: code-group

```sh [tpl/ssh_helper.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" devops@${ip} "$@"
```

:::

3.  **Generate an Executable SSH Script from the Template:**
    Use another `local_file` resource to render the script template, inject necessary variables (like server IP and username), and set executable permissions. Store the generated script in a convenient location, such as a `bin` directory.

::: code-group

```hcl [main.tf]
# Generate the executable SSH helper script
resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh_helper.sh", {
    ip   = hcloud_server.debian_server.ipv4_address // Inject server IP address
    user = "devops"                                 // Inject the login username
  })
  filename        = "bin/ssh-to-server"      // Output script path
  file_permission = "700"                   // Set executable permissions

  # Ensure the known_hosts file is generated before this script
  depends_on = [local_file.known_hosts]
}
```

:::

After applying your Terraform configuration (`terraform apply`), you can connect to your server using the generated helper script. This method avoids the SSH host key mismatch warnings by using a dedicated `known_hosts` file for the connection.

```sh
./bin/ssh-to-server # You can pass additional SSH arguments, e.g., ./bin/ssh-to-server -v
```

This approach streamlines connections to frequently recreated servers, provided the host key specified in `gen/known_hosts_for_server` aligns with the server's actual host key.
