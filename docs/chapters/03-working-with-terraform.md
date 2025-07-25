# Working with Terraform

> This guide explains how to use Terraform to provision and manage resources on Hetzner Cloud.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account (if you don't have one, follow our guide
  on [Creating a Hetzner Account](01-hetzner-cloud#_1-creating-a-hetzner-account))
- Familiarity with command-line interfaces
- Terraform installed on your local machine
- A Hetzner Cloud API Token

## External Resources

For more in-depth information about Terraform and infrastructure as code:

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs) - Official Terraform documentation
- [Arch Wiki: Terraform](https://wiki.archlinux.org/title/Terraform) - Terraform installation and usage
- [Hetzner Cloud Provider Documentation](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs) -
  Hetzner Cloud provider details

## Knowledge

For comprehensive information about Terraform concepts, see [Terraform](/knowledge/terraform).

## 1. Install Terraform

Before you begin, you need to install Terraform. Follow the official installation guide for your operating system on
the [Terraform website](https://developer.hashicorp.com/terraform/downloads).

## 2. Obtain a Hetzner Cloud API Token

To allow Terraform to interact with your Hetzner Cloud account, you need to generate an API token.

1. Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/) and log in.
2. Select your project.
3. Navigate to "Security" -> "API Tokens".
4. Click "Generate API Token".
5. Enter a descriptive name for the token and click "Generate API token".
6. **Crucially, copy the generated token's value immediately.** This token is only shown once and cannot be retrieved
   later. Store it securely, for example, in a password manager.

## 3. Terraform Introduction and Basic Configuration

Terraform uses configuration files to define the infrastructure you want to manage. These files are written in HashiCorp
Configuration Language (`HCL`).

1. Create a new directory for your project.
2. Inside this directory, create a new file named `main.tf`.
3. Open `main.tf` in your text editor or IDE and add the following basic configuration:

::: code-group

```hcl [main.tf]
   # Define Hetzner cloud provider
   terraform {
     required_providers {
       hcloud = {
         source = "hetznercloud/hcloud"
       }
     }
     required_version = ">= 0.13"
   }

   # Configure the Hetzner Cloud API token
   provider "hcloud" {
     token = "your_api_token_goes_here" # Replace with your actual token (temporarily for basic test)
   }

   # Create a server
   resource "hcloud_server" "debian_server" {
     name         = "debian-server"
     image        = "debian-12"
     server_type  = "cx22"
   }
```

:::

::: warning
Hardcoding the API token directly in `main.tf` is not recommended for security reasons. We will address
this in a later step.
:::

## 4. Creating and Managing the Server

For a list of essential Terraform commands and their explanations, refer to
our [Terraform Commands Knowledge Page](/knowledge/terraform).

## 5. Improving the Server Configuration

The basic configuration has some limitations, including hardcoded secrets and lack of essential security features like
firewalls and SSH key access.

### 5.1 Securely Storing the API Token

Storing secrets like API tokens directly in your configuration files is insecure, especially if you use version control.
Terraform variables provide a secure way to handle sensitive data.

1. Create a new file named `variables.tf` in the same directory:

```hcl
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type = string
  nullable    = false
  sensitive   = true
}
```

The `sensitive = true` flag prevents Terraform from outputting the variable's value in the plan or apply output.

2. Create a new file named `providers.tf` in the same directory:

```hcl
provider "hcloud" {
  token = var.hcloud_token
}
```

This tells the `hcloud` provider to use the value of the `hcloud_token` variable for authentication.

3. Create a file named `secret.auto.tfvars` in the same directory:

::: code-group

```sh [Bash]
export TF_VAR_hcloud_token="your_api_key"
```

```sh [PowerShell]
$env:TF_VAR_hcloud_token="your_api_key"
```

:::

**Do not version this `secret.auto.tfvars` file, make sure to add the line `**/secret.auto.tfvars`to your`.gitignore` to
ignore all occurances of this file\*\*

### 5.2 Adding a Firewall

Firewalls are essential for securing your server by controlling incoming and outgoing traffic.

1. Add the following resource block to your `main.tf` to define a firewall that allows SSH access (port 22 TCP) from
   anywhere:

::: code-group

```hcl [main.tf]
   resource "hcloud_firewall" "ssh_firewall" {  //[!code ++:9]
     name = "ssh-firewall"
     rule {
       direction  = "in"
       protocol   = "tcp"
       port       = "22"
       source_ips = ["0.0.0.0/0", "::/0"]
     }
   }
```

:::

2. Associate the firewall with your server resource by adding the `firewall_ids` argument within the `hcloud_server`
   resource block in `main.tf`:

::: code-group

```hcl [main.tf]
   resource "hcloud_server" "debian_server" {
     name         = "debian-server"
     image        = "debian-12"
     server_type  = "cx22"
     firewall_ids = [hcloud_firewall.ssh_firewall.id] //[!code ++]
   }
```

:::

### 5.3 Adding SSH Keys

Adding SSH keys allows you to securely log in to your server without using passwords.

1. Add a resource block for each SSH key you want to add to `main.tf`. If needed adjust the `name` and `public_key`
   values accordingly:

::: code-group

```hcl [main.tf]
   resource "hcloud_ssh_key" "user_ssh_key" {
     name       = "name@device"
     public_key = file("~/.ssh/id_ed25519.pub")
   }
```

:::

2. Associate the SSH keys with your server resource by adding the `ssh_keys` argument within the `hcloud_server`
   resource block in `main.tf`. If you have multiple keys, separate their IDs with commas.

::: code-group

```hcl [main.tf]
   resource "hcloud_server" "debian_server" {
     name         = "debian-server"
     image        = "debian-12"
     server_type  = "cx22"
     firewall_ids = [hcloud_firewall.ssh_firewall.id]
     ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
   }
```

:::

### 5.4 Terraform Output

Terraform outputs allow you to easily retrieve information about your created resources after applying the
configuration.

1. Create a new file named `outputs.tf` in the same directory:

```hcl
output "server_ip_addr" {
  value       = hcloud_server.debian_server.ipv4_address
  description = "The server's IPv4 address"
}

output "server_datacenter" {
  value       = hcloud_server.debian_server.datacenter
  description = "The server's datacenter"
}
```

Now, after running `terraform apply`, Terraform will display the values of these outputs in your terminal.

After applying, you'll see output like:

```sh
terraform apply
...
server_ip_addr="37.27.22.189"
server_datacenter="nbg1-dc3"
```
