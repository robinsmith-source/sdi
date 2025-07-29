# Working with Terraform

> This chapter explains how to use Terraform to provision and manage resources on Hetzner Cloud.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account.
- An SSH key pair, as covered in the [Using SSH](/chapters/02-using-ssh) chapter.
- Terraform installed on your local machine.

## External Resources

For more in-depth information about Terraform and infrastructure as code:

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Core-Workflow](https://developer.hashicorp.com/terraform/intro/core-workflow)
- [Hetzner Cloud Provider Documentation](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)

::: tip
For comprehensive information about Terraform concepts, see [Terraform Concepts](/knowledge/terraform).
:::

## 1. Install Terraform

Before you begin, you need to install Terraform. Follow the official installation guide for your operating system on
the [Terraform website](https://developer.hashicorp.com/terraform/downloads).

## 2. Obtain a Hetzner Cloud API Token

To allow Terraform to interact with your Hetzner Cloud account, you need to generate an API token.

1. Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/) and log in.
2. Select your project.
3. Navigate to "Security" -> "API Tokens".
4. Click "Generate API Token".
5. Enter a descriptive name for the token and click "Generate API Token".
6. **Crucially, copy the generated token's value immediately.** This token is only shown once and cannot be retrieved
   later. Store it securely, for example, in a password manager.

## 3. Terraform Introduction and Basic Configuration [Exercise 11] {exercise-11}

Terraform uses configuration files to define the infrastructure you want to manage. These files are written in HashiCorp
Configuration Language (`HCL`). Let's start with a basic configuration to create a simple server.

::: info
This basic configuration will create a minimal server without security features. You'll enhance it in later sections.
:::

1. Create a new directory for your project.
2. Inside this directory, create a new file named `main.tf`.
3. Open `main.tf` in your text editor or IDE and add the following basic configuration:

::: code-group

```hcl [main.tf]
# Define Hetzner Cloud provider
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
  token = "YOUR_API_TOKEN"
}

# Create a server
resource "hcloud_server" "debian_server" {
  name        = "debian-server"
  image       = "debian-12"
  server_type = "cx22"
}
```

:::

::: warning
Hardcoding the API token directly in `main.tf` is not recommended for security reasons. You'll address this in a later step. **Do not commit this file to version control!**
:::

## 4. Creating and Managing the Server

For a list of essential Terraform commands and their explanations, refer to
our [Terraform Commands Knowledge Page](/knowledge/terraform). The basic workflow involves:

1. **`terraform init`** - Initialize the working directory
2. **`terraform plan`** - Preview changes before applying
3. **`terraform apply`** - Apply the configuration to create resources
4. **`terraform destroy`** - Remove all resources when done

## 5. Improving the Server Configuration

The basic configuration you created has several limitations, including hardcoded secrets and lack of essential security features such as
firewalls and SSH key access. Let's address these issues step by step.

### 5.1 Securely Storing the API Token

Storing secrets such as API tokens directly in your configuration files is insecure, especially if you use version control.
Terraform variables provide a secure way to handle sensitive data. Let's move the API token to a separate variable file.

1. Create a new file named `variables.tf` in the same directory:

```hcl
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  nullable    = false
  sensitive   = true
}
```

The `sensitive = true` flag prevents Terraform from outputting the variable's value in the plan or apply output.

2. Create a new file named `providers.tf` in the same directory:

```hcl
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.hcloud_token
}
```

This defines the used providers and the required version of Terraform. 
It also tells the `hcloud` provider to use the value of the `hcloud_token` variable for authentication.

3. Create a file named `secret.auto.tfvars` in the same directory:

::: code-group

```sh [Bash]
export TF_VAR_hcloud_token="YOUR_API_TOKEN"
```

```sh [PowerShell]
$env:TF_VAR_hcloud_token="YOUR_API_TOKEN"
```

:::

::: warning
Do not version this `secret.auto.tfvars` file. Make sure to add the line `**/secret.auto.tfvars` to your `.gitignore` to
ignore all occurrences of this file.
:::

### 5.2 Adding a Firewall

Firewalls are essential for securing your server by controlling incoming and outgoing traffic. Let's add a firewall that allows SSH access while blocking other traffic.

1. Add the following resource block to your `main.tf` to define a firewall that allows SSH access (port `22` TCP) from
   anywhere:

::: code-group

```hcl [main.tf]
resource "hcloud_firewall" "ssh_firewall" {
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
  firewall_ids = [hcloud_firewall.ssh_firewall.id] // [!code ++]
}
```

:::

### 5.3 Adding SSH Keys

Adding SSH keys allows you to securely log in to your server without using passwords. This is more secure than password-based authentication.

1. Add a resource block for each SSH key you want to add to `main.tf`. If needed, adjust the `name` and `public_key`
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
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id] // [!code ++]
}
```

:::

### 5.4 Terraform Output

Terraform outputs allow you to easily retrieve information about your created resources after applying the
configuration. This is useful for getting the server's IP address and other important details.

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

After running `terraform apply`, Terraform will display the values of these outputs in your terminal.

After applying, you'll see output similar to this:

```sh
terraform apply
...
server_ip_addr="37.27.22.189"
server_datacenter="nbg1-dc3"
```
