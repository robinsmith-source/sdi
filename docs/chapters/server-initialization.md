# Server Initialization

When creating servers with Terraform, you often need to run initial setup commands, install packages, or configure users. 

## Using Bash Init Scripts

A straightforward way to initialize a server is by providing a simple bash script. This script executes when the server first boots.

This example demonstrates how to set up a server using a bash init script passed via Terraform. The script updates the server's packages.

::: code-group

```hcl [main.tf]
resource "hcloud_server" "basicServer" {
  name        = "basic-server"
  image       = "debian-12"
  server_type = "cx22"
  user_data   = file("init.sh") // Path to the init script
}
```

```bash [init.sh]
#!/bin/bash
# Update all packages on the first boot
apt update && apt upgrade -y
```

:::

You can expand this script to perform more complex tasks, like installing software. For example, to install Nginx and create a simple default webpage:

```bash [scripts/init-nginx.sh]
#!/bin/bash
# Update packages
apt update && apt upgrade -y

# Install Nginx
apt install -y nginx

# Create a simple HTML page
echo "Hello from my Terraform server!" > /var/www/html/index.html

# Start and enable Nginx service
systemctl start nginx
systemctl enable nginx
```

This script installs Nginx, starts the service, enables it to start on boot, and creates a basic `index.html` file.

While bash scripts are simple for basic tasks, managing complex configurations, user setup, and file writing can become cumbersome. For more structured and powerful initialization, cloud-init is recommended.

## Using Cloud-Init with Cloud-Config YAML

Cloud-init is the industry standard for cross-platform cloud instance initialization. It uses configuration files (often in YAML format using `#cloud-config`) to define setup tasks like package installation, user creation, file writing, and command execution.

## Basic Configuration: Installing Packages

To use cloud-init, create a configuration file (e.g., `userData.yml`) and reference it in Terraform. This example installs Nginx and creates a dynamic index page.


::: code-group
```hcl [main.tf]
# ... existing configuration ...

resource "hcloud_server" "cloudInitServer" {
  name        = "cloud-init-server"
  image       = "debian-12"
  server_type = "cx22"
  # ... other arguments ...
  user_data = file("tpl/userData.yml") // Reference the cloud-config file
}

# ... rest of the file ...
```

```yml [tpl/userData.yml]
#cloud-config
# Install the nginx package
packages:
  - nginx

# Run commands after package installation
runcmd:
  # Ensure nginx starts on boot
  - systemctl enable nginx
  # Clear default nginx content
  - rm /var/www/html/*
  # Create a dynamic index page showing the server's public IP and creation time
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  # Restart SSH (may be needed if other ssh configs are applied)
  - systemctl restart sshd
```
:::

On server creation, cloud-init executes the steps defined in `tpl/userData.yml`. You can verify Nginx installation via SSH (`systemctl status nginx`).

::: details **Note:** Web access (port 80) requires separate firewall configuration.
```hcl {9-14}
resource "hcloud_firewall" "sshFw" {
  name = "ssh-firewall"
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
}
```
:::

## Advanced Configuration: Managing Users and Templating

Cloud-init excels at managing users and SSH access. We can also use Terraform's templating functions to inject variables (like SSH keys) into the cloud-config file.

Update the cloud-config template (`tpl/userData.yml`) to create a user, restrict SSH access, and use variables:


:::code-group
```yml [tpl/userData.yml]
#cloud-config
# Define users
users:
 - name: ${loginUser}           # Variable for the username (e.g., "devops")
   groups: sudo                # Add user to sudo group
   shell: /bin/bash
   sudo: ALL=(ALL) NOPASSWD:ALL # Allow sudo without password
   ssh_authorized_keys:        # List of public keys allowed to log in
    - ${public_key_one}        # Variable for the first public key
    - ${public_key_two}        # Variable for the second public key
    # Add more keys as needed

# Write configuration files
write_files:
 - content: |                   # Content for the SSH restriction file
    # Restrict SSH access
    AllowUsers ${loginUser}     # Only allow the specified user
    PasswordAuthentication no   # Disable password login
    PermitRootLogin no          # Disable root login
    ChallengeResponseAuthentication no
    UsePAM yes                  # Keep PAM enabled (often needed)
   path: /etc/ssh/sshd_config.d/99-restrict-ssh.conf # Path for the SSH config snippet
   permissions: '0644'         # Standard permissions for config files

# Install packages (can be combined with user setup)
packages:
  - nginx

# Run commands (executes after users and files are processed)
runcmd:
  - systemctl enable nginx
  - rm /var/www/html/*
  - >
    echo "I'm Nginx @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  - systemctl restart sshd      # Restart sshd service to apply access changes
```
:::

To process this template and inject values:

1.  Ensure `userData.yml` is in a `tpl` directory (e.g., `tpl/userData.yml`).
2.  Use a `local_file` resource in `main.tf` to render the template:


::: code-group

```hcl [main.tf]
# ... existing configuration ...

# Assume hcloud_ssh_key resources named 'userKeyOne' and 'userKeyTwo' exist
resource "hcloud_ssh_key" "userKeyOne" {
  name       = "user-key-one"
  public_key = file("~/.ssh/id_rsa.pub") # Example path
}
resource "hcloud_ssh_key" "userKeyTwo" {
  name       = "user-key-two"
  public_key = file("~/.ssh/another_key.pub") # Example path
}


# Render the cloud-init template
resource "local_file" "user_data_rendered" {
  content = templatefile("tpl/userData.yml", {
    loginUser      = "devops" # Define the username
    public_key_one = hcloud_ssh_key.userKeyOne.public_key # Pass public keys
    public_key_two = hcloud_ssh_key.userKeyTwo.public_key
    # Add other variables as needed
  })
  filename = "gen/userData.yml" # Output path for the processed file
}

# ... other resources ...
```
:::

3.  Update the server resource to use the *rendered* content:

::: code-group

```hcl [main.tf]
# ... existing configuration ...

resource "hcloud_server" "cloudInitServer" {
  # ... other arguments ...
  user_data = local_file.user_data_rendered.content # Use the rendered template content
}

# ... rest of the file ...
```
:::

Now, `terraform apply` will generate `gen/userData.yml` with substituted values and pass it to the server.

## Handling SSH Host Key Changes

When you destroy and recreate a server, it typically gets a new SSH host key. If the IP address remains the same (or is reused), your SSH client will warn about a potential "man-in-the-middle" attack because the host key stored in your local `~/.ssh/known_hosts` file no longer matches the server's new key.

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```

A robust solution involves generating a persistent host key pair with Terraform and configuring the server via cloud-init to use it. However, a simpler approach for managing connections is to generate a specific `known_hosts` file via Terraform and use a helper script for SSH connections.

1.  **Generate `known_hosts` entry:** Create a `local_file` resource containing the server's IP and its expected public host key. *(Note: This example assumes you manage the host key via Terraform, e.g., using `tls_private_key`. If the server generates its own key ephemerally, this won't prevent the warning without more advanced cloud-init setup.)*


::: code-group
```hcl [main.tf]
# Assume tls_private_key.host_key exists and manages the server's host key
resource "tls_private_key" "host_key" {
  algorithm = "ED25519"
}

# Generate a known_hosts file entry
resource "local_file" "known_hosts_entry" {
  content  = "${hcloud_server.cloudInitServer.ipv4_address} ${tls_private_key.host_key.public_key_openssh}"
  filename = "gen/known_hosts" # Output file in the gen directory
}
```
:::

2.  **Create SSH Helper Script Template:** Create a script template (`tpl/ssh_helper.sh`) that uses the generated `known_hosts` file.

::: code-group
```bash [tpl/ssh_helper.sh]
#!/usr/bin/env bash

# Get the directory containing this script
SCRIPT_DIR=$(dirname "$0")
# Construct the path to the gen directory (assuming bin and gen are siblings)
GEN_DIR="$SCRIPT_DIR/../gen"
KNOWN_HOSTS_FILE="$GEN_DIR/known_hosts"

# Check if the known_hosts file exists
if [ ! -f "$KNOWN_HOSTS_FILE" ]; then
  echo "Error: $KNOWN_HOSTS_FILE not found. Run terraform apply?"
  exit 1
fi

# Execute SSH using the specific known_hosts file
# -o StrictHostKeyChecking=yes # Optional: be strict
# -o UserKnownHostsFile=...   # Point to our generated file
ssh -o UserKnownHostsFile="$KNOWN_HOSTS_FILE" \
    ${user}@${ip} "$@" # Pass username, IP, and any extra arguments
```
:::

3.  **Generate Executable SSH Script:** Use `local_file` again to render the script template and make it executable. Place it in a `bin` directory.


:::: code-group
```hcl [main.tf]
# Generate the executable SSH helper script
resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh_helper.sh", {
    ip   = hcloud_server.cloudInitServer.ipv4_address # Pass server IP
    user = "devops"                                   # Pass login user
  })
  filename        = "bin/ssh-server" # Output script path (e.g., in bin/)
  file_permission = "0700"           # Make it executable (rwx------)

  # Ensure the known_hosts file is created before this script
  depends_on = [local_file.known_hosts_entry]
}
```
:::

After `terraform apply`, you can connect using the script, which bypasses your default `known_hosts` file:

```bash
./bin/ssh-server # Add SSH arguments if needed, e.g., ./bin/ssh-server -v
```

This avoids the host key warning, provided the key in `gen/known_hosts` matches the server's actual host key.
