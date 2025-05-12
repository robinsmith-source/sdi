# Server Initialization Guide

> Efficiently initialize your servers with Terraform by running setup commands, installing packages, or configuring users upon creation.

This guide explores two primary methods for server initialization: basic `Bash` scripts and the more robust Cloud-Init with Cloud-Config.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account
- A Hetzner Cloud API Token
- Terraform installed on your local machine

## 1. Using Bash Init Scripts for Server Initialization

A straightforward approach to server initialization involves providing a `Bash` script that executes during the server's first boot.

This example demonstrates passing a `Bash` script via Terraform to update the server's packages:

::: code-group

```hcl [main.tf]
resource "hcloud_server" "basicServer" {
  name        = "basic-server"
  image       = "debian-12"
  server_type = "cx22"
  user_data   = file("init.sh") // Specifies the path to the initialization script
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

This script performs package updates, installs Nginx, starts the Nginx service, enables it for auto-start on boot, and creates a basic `index.html`.

While Bash scripts are effective for simple initializations, managing intricate configurations, user setups, or extensive file manipulations can become complex. For these scenarios, Cloud-Init offers a more structured and powerful solution.

## 2. Introduction to Cloud-Init for Server Initialization

Cloud-Init is the industry standard for cross-platform cloud instance initialization. It leverages configuration files, commonly written in YAML format using the `#cloud-config` directive, to define tasks such as package installation, user creation, file writing, and command execution. For further information take a look at [this](../utils/cloud-init.md).

## 3. Cloud-Init: Installing Packages

To use Cloud-Init, create a cloud-config `YAML` file (e.g., `userData.yml`) and reference it in your Terraform configuration. The following example installs Nginx and generates a dynamic index page:

::: code-group

```hcl [main.tf]
# ... (ensure other necessary configurations like provider setup are present) ...

resource "hcloud_server" "cloudInitServer" {
  name        = "cloud-init-server"
  image       = "debian-12"
  server_type = "cx22"
  // ... (other server arguments as needed) ...
  user_data = file("tpl/userData.yml") // Reference the cloud-config YAML file
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
resource "hcloud_firewall" "webAccessFw" { // Renamed for clarity
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

Ensure your server is associated with this firewall. Otherwise you can also use ssh port forwarding like described [here](./using-ssh.md#4-ssh-port-forwarding).
:::

## 4. Cloud-Init: User Management and Templating

Cloud-Init excels at tasks like managing user accounts and SSH access. Furthermore, Terraform's templating capabilities allow you to dynamically inject variables (such as SSH public keys) into your cloud-config files.

Update your cloud-config template (`tpl/userData.yml`) to include user creation, SSH access restrictions, and variable usage:

:::code-group

```yml [tpl/userData.yml]
# Define user accounts  
users:
  - name: ${loginUser} # Username (e.g., "devops"), injected from Terraform
    groups: sudo # Add user to the sudo group
    shell: /bin/bash # Set default shell
    sudo: ALL=(ALL) NOPASSWD:ALL # Grant sudo privileges without password prompt
    ssh_authorized_keys: # List of authorized public SSH keys
      - ${public_key_one} # First public key, injected from Terraform
      - ${public_key_two} # Second public key, injected from Terraform
      # Add more public keys as needed

# Write configuration files to the server
write_files:
  - content: | # Content for SSH daemon configuration snippet
      # SSH Access Restrictions
      AllowUsers ${loginUser}     # Only permit login for the specified user
      PasswordAuthentication no   # Disable password-based SSH authentication
      PermitRootLogin no          # Prohibit root login via SSH
      ChallengeResponseAuthentication no # Disable challenge-response authentication
      UsePAM yes                  # Keep Pluggable Authentication Modules (PAM) enabled
    path: /etc/ssh/sshd_config.d/99-restrict-ssh.conf # Path for the custom SSH configuration
    permissions: "0644" # Standard file permissions for configuration files

# Install necessary packages (can be combined with other directives)
packages:
  - nginx

# Execute commands after users and files are set up
runcmd:
  - systemctl enable nginx
  - rm /var/www/html/*
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  # Restart SSH service to apply new access configurations
  - systemctl restart sshd
```

:::

To process this template and inject the defined variables:

1.  Ensure your `userData.yml` template is located in a `tpl` directory (e.g., `project_root/tpl/userData.yml`).
2.  Define `hcloud_ssh_key` resources for your public keys in `main.tf`.
3.  Use a `local_file` data source in `main.tf` to render the template with variables:

::: code-group

```hcl [main.tf]
# ... (provider configuration and other resources) ...

# Example SSH key resources (replace with your actual key management)
resource "hcloud_ssh_key" "userKeyOne" {
  name       = "user-key-one"
  public_key = file("~/.ssh/id_ed25519.pub") // Path to your first public key
}
resource "hcloud_ssh_key" "userKeyTwo" {
  name       = "user-key-two"
  public_key = file("~/.ssh/another_key.pub") // Path to your second public key
}

# Render the cloud-init template with variables  // [!code ++:10]
resource "local_file" "user_data_rendered" { 
  content = templatefile("tpl/userData.yml", {
    loginUser      = "devops"                             // Define the username to create
    public_key_one = hcloud_ssh_key.userKeyOne.public_key // Pass the first public key
    public_key_two = hcloud_ssh_key.userKeyTwo.public_key // Pass the second public key
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

resource "hcloud_server" "cloudInitServer" { // [!code focus:4]
  // ... (other server arguments: name, image, server_type, etc.)
  user_data = local_file.user_data_rendered.content // Use the rendered template content
}

# ... (rest of your Terraform configuration) ...
```

:::

Running `terraform apply` will now:

1.  Generate the `gen/userData.rendered.yml` file with your specified values substituted for the variables.
2.  Pass this rendered YAML content to the Hetzner Cloud server during its creation.

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
resource "local_file" "known_hosts_entry" {
  content  = "${hcloud_server.cloudInitServer.ipv4_address} ${tls_private_key.host_key.public_key_openssh}"
  filename = "gen/known_hosts_for_server" // Descriptive filename in the 'gen' directory
}
```

:::

2.  **Create an SSH Helper Script Template:**
    Develop a script template (`tpl/ssh_helper.sh`) that instructs the SSH client to use your generated `known_hosts` file.

::: code-group

```sh [tpl/ssh_helper.sh]
#!/usr/bin/env bash

# Determine the script's directory to locate sibling directories
SCRIPT_DIR=$(dirname "$0")
# Path to the generated 'gen' directory (assuming 'bin' and 'gen' are siblings)
GEN_DIR="$SCRIPT_DIR/../gen"
# Specific known_hosts file for this server
KNOWN_HOSTS_FILE="$GEN_DIR/known_hosts_for_server"

# Verify the generated known_hosts file exists
if [ ! -f "$KNOWN_HOSTS_FILE" ]; then
  echo "Error: $KNOWN_HOSTS_FILE not found. Please run 'terraform apply'."
  exit 1
fi

# Execute SSH, forcing the use of our specific known_hosts file
# This bypasses the default ~/.ssh/known_hosts for this connection.
ssh -o UserKnownHostsFile="$KNOWN_HOSTS_FILE" \
    -o StrictHostKeyChecking=yes \ # Optional: Enforce strict checking
    ${user}@${ip} "$@" # Pass username, IP, and any additional SSH arguments
```

:::

3.  **Generate an Executable SSH Script from the Template:**
    Use another `local_file` resource to render the script template, inject necessary variables (like server IP and username), and set executable permissions. Store the generated script in a convenient location, such as a `bin` directory.

::: code-group

```hcl [main.tf]
# Generate the executable SSH helper script
resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh_helper.sh", {
    ip   = hcloud_server.cloudInitServer.ipv4_address // Inject server IP address
    user = "devops"                                   // Inject the login username
  })
  filename        = "bin/ssh-to-server"      // Output script path (e.g., project_root/bin/ssh-to-server)
  file_permission = "0700"                   // Set executable permissions (rwx------)

  # Ensure the known_hosts file is generated before this script
  depends_on = [local_file.known_hosts_entry]
}
```

:::

After applying your Terraform configuration (`terraform apply`), you can connect to your server using the generated helper script. This method avoids the SSH host key mismatch warnings by using a dedicated `known_hosts` file for the connection.

```sh
./bin/ssh-to-server # You can pass additional SSH arguments, e.g., ./bin/ssh-to-server -v
```

This approach streamlines connections to frequently recreated servers, provided the host key specified in `gen/known_hosts_for_server` aligns with the server's actual host key.
