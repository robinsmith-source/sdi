# Terraform Modules

> This guide covers creating and using Terraform modules to organize and reuse infrastructure code. It demonstrates a practical example of building a reusable module for generating SSH helper scripts.

## Prerequisites

Before you begin, you should have an existing Terraform project that can provision a server, as covered in the previous chapters.

## External Resources

For more in-depth technical information about modules in Terraform:

- [Terraform Documentation: Modules](https://www.terraform.io/language/modules) - Official Terraform documentation on modules
- [Terraform Documentation: Module Sources](https://www.terraform.io/language/modules/sources) - Detailed guide on module sources

::: tip
For comprehensive information about Terraform concepts, see [Terraform Concepts](/knowledge/terraform).
:::

## 1. Understanding Terraform Modules

Terraform modules are self-contained packages of Terraform configurations that manage a collection of related infrastructure resources. They are the main way to package and reuse resource configurations with Terraform.

Modules allow you to:

- **Organize Configuration:** Group related resources together, making your code easier to understand and manage.
- **Encapsulate Complexity:** Hide the complex details of a resource collection behind a simple interface.
- **Reuse Code:** Use the same module multiple times within your configuration or in different projects.
- **Maintain Consistency:** Ensure that resources are created with a consistent configuration.

In the next section, you will build a practical module to solve a recurring problem: simplifying SSH access to newly created servers.

## 2. Creating an SSH Wrapper Module [Exercise 17] {#exercise-17}

When connecting to newly created servers via SSH, you typically encounter host key verification warnings, as mentioned in the [Server Initialization](/chapters/04-server-initialization#_3-generating-helper-scripts-exercise-14) chapter. You can create a reusable Terraform module that automatically generates SSH and SCP wrapper scripts to handle this for you.

### 2.1. Module and Project Structure

First, organize your files. You will have a `modules` directory that contains your reusable `ssh-wrapper` module, and an `exercise` directory where you will use this module.

```sh
.
├── exercise/
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
│   └── ...
└── modules/  # [!code ++:7]
    └── ssh-wrapper/
        ├── main.tf
        ├── variables.tf
        └── tpl/
            ├── scp.sh
            └── ssh.sh
```

### 2.2. Creating the Module Templates

The module will use template files from [Exercise 14](/chapters/04-server-initialization#exercise-14) for the `ssh` and `scp` scripts. These templates contain placeholders that Terraform will populate.

::: code-group

```sh [modules/ssh-wrapper/tpl/scp.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

if [ $# -lt 2 ]; then
   echo usage: ./bin/scp <arguments>
else
   scp -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${host} $@
fi
```

```sh [modules/ssh-wrapper/tpl/ssh.sh]
#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${ip} "$@"
```

:::

### 2.3. Implementing the Module

Now, define the module's input variables and the resources it will create. The module will take the server's IPv4 address, the user's public key and optionally a user to log on to the machine.This module will generate a `known_hosts` file along with the executable wrapper scripts (`scp.sh` and `ssh.sh`).

::: code-group

```hcl [modules/ssh-wrapper/main.tf]
resource "local_file" "known_hosts" {
  content         = "${local.target_host} ${var.public_key}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

# Generate SSH wrapper script from template
resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh.sh", {
    host = var.ipv4Address
    user = var.login_user
  })
  filename        = "bin/ssh"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}

# Generate SCP wrapper script from template
resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp.sh", {
    host = var.ipv4Address,
    user = var.login_user
  })
  filename        = "bin/scp"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}
```

```hcl [modules/ssh-wrapper/variables.tf]
variable "login_user" {
  description = "The user to login to the server"
  type    = string
  nullable = false
  default = "root"
}

variable "public_key" {
  description = "The public key to use for the server"
  type     = string
  nullable = false
}

variable "ipv4Address" {
  description = "The IPv4 address of the server"
  type     = string
  nullable = false
}
```

:::

### 2.4. Using the Module in Your Project

With the module created, you can now use it in your main project configuration. In your `exercise/<YOUR_EXERCISE_NUMBER>/main.tf`, you'll provision a server and then call the `ssh-wrapper` module, passing the server's IP and public key to it.

::: code-group

```hcl [exercise/main.tf]
resource "hcloud_ssh_key" "user_ssh_key" {
  name       = "robin@Robin-Laptop"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_firewall" "ssh_firewall" {
  name = "ssh-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "debian_server" {
  location     = "hel1"
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.ssh_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
}

module "ssh_wrapper" { // [!code ++:6]
  source      = "../modules/ssh-wrapper"
  login_user   = var.login_user
  ipv4Address = hcloud_server.debian_server.ipv4_address
  public_key  = file("~/.ssh/id_ed25519.pub")
}
```

:::

### 2.5. Verifying the Module's Output

After running `terraform apply`, your project directory will contain the generated files.

- `gen/known_hosts`: Contains the server's IP and public key.
- `bin/ssh`: The executable SSH wrapper script.
- `bin/scp`: The executable SCP wrapper script.

You can now test the scripts to connect to your server without any host key verification warnings.

```sh
# Check that the files were created
ls -l bin/
ls -l gen/

# Test the SSH connection
./bin/ssh "echo 'SSH connection successful!'"

# Test file transfer
echo "Hello from my local machine" > test.txt
./bin/scp test.txt root@server:~/test.txt
```

By creating and using this module, you've made your SSH workflow more secure and convenient, and you now have a reusable component you can share across projects.
