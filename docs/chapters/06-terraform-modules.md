# Terraform Modules

> This guide covers creating and using Terraform modules to organize and reuse infrastructure code. It demonstrates
> practical examples including server provisioning and SSH configuration management.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account
- A Hetzner Cloud API Token
- Terraform installed on your local machine
- Basic understanding of Terraform resources and variables
- An SSH client:
  - macOS and Linux: Built-in OpenSSH client
  - Windows: Windows Terminal with OpenSSH or PuTTY

## External Resources

For more in-depth technical information about modules in Terraform:

- [Terraform Documentation: Modules](https://www.terraform.io/language/modules) - Official Terraform documentation on
  modules
- [Terraform Documentation: Module Sources](https://www.terraform.io/language/modules/sources) - Detailed guide on
  module sources

::: info
For comprehensive information about Terraform concepts, see [Terraform](/knowledge/terraform).
:::

## 1. Creating a Host Metadata Module

Terraform modules are reusable, self-contained packages of Terraform configurations that manage a collection of related
infrastructure resources. They enable you to organize, encapsulate, and share infrastructure code.

Let's start with a simple example that creates a JSON metadata file for a Hetzner Cloud server.

### Parent and Child Module Layout

```
root/
├── exercise/
│   ├── main.tf
│   └── variables.tf
└── modules/
    └── host-metadata/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── providers.tf
        └── tpl/
            └── hostData.json
```

### Child Module Implementation

Create the child module that manages the server and metadata:

::: code-group

```hcl [variables.tf]
variable "location" {
  type     = string
  nullable = false
}

variable "ipv4Address" {
  type     = string
  nullable = false
}
variable "ipv6Address" {
  type     = string
  nullable = false
}

variable "name" {
  type     = string
  nullable = false
}
```

```hcl [main.tf]
resource "local_file" "host_data" {
  content = templatefile("${path.module}/tpl/hostData.json", {
    ip4      = var.ipv4Address
    ip6      = var.ipv6Address
    location = var.location
  })
  filename = "gen/${var.name}.json"
}
```

```json [tpl/hostdata.json]
{
  "network": {
    "ipv4": "${ip4}",
    "ipv6": "${ip6}"
  },
  "location": "${location}"
}
```

:::

This module will create a JSON file with the server's metadata and place it in the `gen` directory of the parent module.

### Parent Module Implementation

Create the parent module that calls the child module:

::: code-group

```hcl [variables.tf]
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type = string
  nullable    = false
  sensitive   = true
}
```

```hcl [main.tf]
# ... (firewall configuration and other resources) ...

# Create a Hetzner Cloud server // [!code focus:17]
resource "hcloud_server" "debian_server" {
  location    = "hel1"
  name        = "debian-server"
  image       = "debian-12"
  server_type = "cx22"
  ssh_keys    = [hcloud_ssh_key.user_ssh_key.id]
}

# Use the SSH Known Hosts module
module "ssh_wrapper" {
  source      = "../modules/ssh-wrapper"
  loginUser   = "root"
  ipv4Address = hcloud_server.debian_server.ipv4_address
  public_key  = file("~/.ssh/id_ed25519.pub")
}
```

:::

## 2. SSH Known Hosts Module [Exercise 17]

When connecting to newly created servers via SSH, you typically encounter host key verification warnings like already
mentioned in [Server Initialization](/chapters/04-server-initialization#_5-handling-ssh-host-key-mismatches-exercise-14). So we will create a module that automatically
generates SSH configuration files to eliminate these warnings.

### Module Structure

Create the following directory structure for your SSH known hosts module:

```sh
.
├── exercise/
│   ├── main.tf
│   ├── variables.tf
│   ├── providers.tf
│   └── ...
└── modules/
    └── ssh-wrapper/  # [!code ++:7]
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── tpl/
            ├── ssh.sh
            └── scp.sh
```

### Creating the Module Templates

First, create the script templates that Terraform will process:

::: code-group

```sh [tpl/ssh.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${ip} "$@"
```

```sh [tpl/scp.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

if [ $# -lt 2 ]; then
   echo "usage: .../bin/scp ... {user}@${ip} ..."
else
   scp -o UserKnownHostsFile="$GEN_DIR/known_hosts" "$@"
fi
```

:::

The template variables `${user}` and `${ip}` will be replaced with actual values when Terraform processes the templates.

### Module Implementation

Define the module's variables, resources, and outputs:

::: code-group

```hcl [variables.tf]
variable "loginUser" {
  type        = string
  default     = "root"
}

variable "public_key" {
  type = string
  nullable = false
}

variable "ipv4Address" {
  type     = string
  nullable = false
}
```

```hcl [main.tf]
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
    ip   = var.ipv4Address
    user = var.loginUser
  })
  filename        = "bin/scp"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}
```

:::

### Using the Module

Implement the module in your main Terraform configuration:

::: code-group

```hcl [main.tf]
# ... (firewall configuration and other resources) ...

# Create a Hetzner Cloud server // [!code focus:17]
resource "hcloud_server" "debian_server" {
  location    = "hel1"
  name        = "debian-server"
  image       = "debian-12"
  server_type = "cx22"
  ssh_keys    = [hcloud_ssh_key.user_ssh_key.id]
}

# Use the SSH Known Hosts module // [!code ++:7]
module "ssh_wrapper" {
  source      = "../modules/ssh-wrapper"
  loginUser   = "root"
  ipv4Address = hcloud_server.debian_server.ipv4_address
  public_key  = file("~/.ssh/id_ed25519.pub")
}
```

```hcl [variables.tf]
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type = string
  nullable    = false
  sensitive   = true
}
```

:::

### Generated Files

After running `terraform apply`, the module will generate:

- `gen/known_hosts` - Contains the server's SSH host key
- `bin/ssh` - SSH wrapper script with proper known_hosts configuration
- `bin/scp` - SCP wrapper script for file transfers

Example generated files:

```text
# gen/known_hosts
157.180.78.16 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDd+x7b80BM97rTU4RCM/CP+K7u4QAqx8ulDdXm9JDv
```

```sh
# bin/ssh
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" devops@157.180.78.16 "$@"
```

### Testing the Module

Test your implementation with these commands:

```sh
# Test SSH connection (should work without host key warnings)
./bin/ssh "echo 'SSH connection successful!'"

# Test file transfer
echo "Hello from local machine" > test.txt
./bin/scp test.txt devops@server:~/

# Copy file from server
./bin/scp devops@server:~/test.txt ./downloaded.txt
```

The scripts should work without prompting for host key verification, providing seamless access to your infrastructure.

## 3. Testing Your Module

After applying your Terraform configuration, verify that the module works correctly:

```sh
# Apply the module
terraform apply

# Check that all files were created
ls -la bin/
ls -la gen/

# Test SSH connection (should work without host key warnings)
./bin/ssh "echo 'SSH connection successful!'"

# Test file transfer
echo "Hello from local machine" > test.txt
./bin/scp test.txt devops@server:~/
./bin/scp devops@server:~/test.txt ./downloaded.txt
```

The scripts should work without prompting for host key verification, providing seamless access to your infrastructure.
