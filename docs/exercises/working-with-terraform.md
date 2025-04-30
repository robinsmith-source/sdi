# Working with Terraform

This guide explains how to use Terraform to provision and manage resources on Hetzner Cloud.

## 1. Install Terraform

Before you begin, you need to install Terraform. Follow the official installation guide for your operating system on the [Terraform website](https://developer.hashicorp.com/terraform/downloads).

## 2. Obtain a Hetzner Cloud API Token

To allow Terraform to interact with your Hetzner Cloud account, you need to generate an API token.

1.  Go to the [Hetzner Cloud Console](https://console.hetzner.cloud/) and log in.
2.  Select your project.
3.  Navigate to "Security" -> "API Tokens".
4.  Click "Generate API Token".
5.  Enter a descriptive name for the token and click "Generate API token".
6.  **Crucially, copy the generated token's value immediately.** This token is only shown once and cannot be retrieved later. Store it securely, for example, in a password manager.

## 3. Terraform Introduction and Basic Configuration

Terraform uses configuration files to define the infrastructure you want to manage. These files are written in HashiCorp Configuration Language (`HCL`).

1.  Create a new directory for your project.
2.  Inside this directory, create a new file named `main.tf`.
3.  Open `main.tf` in your text editor or IDE and add the following basic configuration:

    ```hcl
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
    resource "hcloud_server" "helloServer" {
      name         = "hello"
      image        = "debian-12"
      server_type  = "cx22"
    }
    ```

    **Note:** Hardcoding the API token directly in `main.tf` is not recommended for security reasons. We will address this in a later step.

## 4. Creating and Managing the Server

You can now use Terraform commands to initialize your project, plan the changes, and apply them to create the server.

1.  Open your terminal and navigate to the directory containing your `main.tf` file.
2.  Initialize the Terraform project. This downloads the necessary provider plugins:
    ```bash
    terraform init
    ```
3.  Generate an execution plan. This shows you which actions Terraform will perform:
    ```bash
    terraform plan
    ```
4.  Apply the configuration to create the server:

    ```bash
    terraform apply
    ```

    Terraform will show you the plan again and ask for confirmation before creating the resources. You will be prompted to enter `yes` to proceed.

5.  Verify the server creation by logging into the [Hetzner Cloud Console](https://console.hetzner.cloud/).

6.  After you are finished, you can destroy the created resources using:
    ```bash
    terraform destroy
    ```
    Terraform will show you the resources to be destroyed and ask for confirmation.

## 5. Improving the Server Configuration

The basic configuration has some limitations, including hardcoded secrets and lack of essential security features like firewalls and SSH key access.

### Securely Storing the API Token

Storing secrets like API tokens directly in your configuration files is insecure, especially if you use version control. Terraform variables provide a secure way to handle sensitive data.

1.  Create a new file named `variables.tf` in the same directory:

```hcl
   variable "hcloud_token" {
      description = "Hetzner Cloud API token"
      nullable    = false
      sensitive   = true
   }
```

The `sensitive = true` flag prevents Terraform from outputting the variable's value in the plan or apply output.

2.  Create a new file named `providers.tf` in the same directory:

```hcl
provider "hcloud" {
   token = var.hcloud_token
}
```

This tells the `hcloud` provider to use the value of the `hcloud_token` variable for authentication.

3.  Create a file named `secret.auto.tfvars` in the same directory:
    ::: details Bash {open}

```bash
export TF_VAR_hcloud_token="your_api_key"
```

:::

::: details Windows Powershell {open}

```bash
$env:TF_VAR_hcloud_token="your_api_key"
```

:::

**Do not version this `secret.auto.tfvars` file, make sure to add the line `**/secret.auto.tfvars`to your`.gitignore` to ignore all occurances of this file\*\*

### Adding a Firewall

Firewalls are essential for securing your server by controlling incoming and outgoing traffic.

1.  Add the following resource block to your `main.tf` to define a firewall that allows SSH access (port 22 TCP) from anywhere:

    ```hcl
    resource "hcloud_firewall" "sshFw" {
      name = "ssh-firewall"
      rule {
        direction  = "in"
        protocol   = "tcp"
        port       = "22"
        source_ips = ["0.0.0.0/0", "::/0"]
      }
    }
    ```

2.  Associate the firewall with your server resource by adding the `firewall_ids` argument within the `hcloud_server` resource block in `main.tf`:

    ```hcl
    resource "hcloud_server" "helloServer" {
      name         = "hello"
      image        = "debian-12"
      server_type  = "cx22"
      firewall_ids = [hcloud_firewall.sshFw.id]
    }
    ```

### Adding SSH Keys

Adding SSH keys allows you to securely log in to your server without using passwords.

1.  Add a resource block for each SSH key you want to add to `main.tf`. If needed adjust the `name` and `public_key` values accordingly:

    ```hcl
    resource "hcloud_ssh_key" "loginUser" {
      name       = "name@device"
      public_key = file("~/.ssh/id_ed25519.pub")
    }
    ```

2.  Associate the SSH keys with your server resource by adding the `ssh_keys` argument within the `hcloud_server` resource block in `main.tf`. If you have multiple keys, separate their IDs with commas.

    ```hcl
    resource "hcloud_server" "helloServer" {
      name         = "hello"
      image        = "debian-12"
      server_type  = "cx22"
      firewall_ids = [hcloud_firewall.sshFw.id]
      ssh_keys     = [hcloud_ssh_key.loginUser.id]
    }
    ```

### Terraform Output

Terraform outputs allow you to easily retrieve information about your created resources after applying the configuration.

1.  Create a new file named `outputs.tf` in the same directory:

```hcl
output "hello_ip_addr" {
value       = hcloud_server.helloServer.ipv4_address
description = "The server's IPv4 address"
}

output "hello_datacenter" {
value       = hcloud_server.helloServer.datacenter
description = "The server's datacenter"
}
```

Now, after running `terraform apply`, Terraform will display the values of these outputs in your terminal.
