# Terraform <Badge type="info" text="IaC" />

Terraform is a powerful **Infrastructure as Code (IaC)** tool by HashiCorp. It allows you to define, provision, and manage cloud and on-prem infrastructure using a declarative configuration language called **HCL (HashiCorp Configuration Language)**.

::: info Why Use Terraform?

- **Declarative Approach:** Define the desired _end state_ of your infrastructure, and Terraform figures out how to achieve it.
- **Automation:** Reduces manual effort and errors in provisioning and management.
- **Version Control:** Treat your infrastructure like code – track changes, review, and collaborate using Git.
- **Reusability:** Use modules to create reusable infrastructure components.
- **Multi-Cloud:** Manage resources across various cloud providers (AWS, Azure, GCP, Hetzner Cloud, etc.) and other services with a single workflow.
  :::

## Core Workflow & Concepts {#core-workflow}

Terraform follows a simple yet powerful workflow: **Write -> Plan -> Apply**.

1.  **Write:** Define your infrastructure resources in `.tf` configuration files using HCL.
2.  **Plan:** Run `terraform plan` to preview the changes Terraform will make to reach your desired state.
3.  **Apply:** Run `terraform apply` to execute the changes outlined in the plan.

### Key Concepts Explained

::: details Infrastructure as Code (IaC)
Define and manage infrastructure through code, rather than manual processes. Enables versioning, automation, and repeatability.
:::

::: details Execution Plans
Terraform determines what actions (create, update, destroy) are needed by comparing your configuration to the current state. The plan shows these proposed actions _before_ they happen.
:::

::: details Resource Graph
Terraform builds a dependency graph of your resources to understand relationships and parallelize operations where possible, speeding up provisioning.
:::

::: details Change Automation
Apply complex infrastructure changes reliably and predictably, minimizing human error.
:::

## Essential Commands <Badge type="tip" text="Core CLI" />

Mastering these commands is key to using Terraform effectively.

::: code-group

```sh [1. Initialize]
terraform init

# Downloads provider plugins and modules
# Run once per project, or after adding new providers/modules
```

```sh [2. Format & Validate]
terraform fmt

# Automatically formats your .tf files for consistency

terraform validate

# Checks syntax and basic configuration errors locally
```

```sh [3. Plan]
terraform plan

# Shows what changes Terraform will make
# (+) create, (-) destroy, (~) update in-place

terraform plan -out=tfplan

# Save the plan to a file for later application
```

```sh [4. Apply]
terraform apply

# Executes the changes outlined in the plan
# Prompts for confirmation unless -auto-approve is used

terraform apply tfplan

# Apply a previously saved plan file

terraform apply -auto-approve

# Auto-approve (Use with caution, e.g., in CI/CD)
```

```sh [5. Destroy]
terraform destroy

# Removes all resources managed by this configuration
# Shows a plan first, prompts for confirmation

terraform destroy -auto-approve

# Auto-approve destruction (Use with extreme caution!)
```

:::

::: warning Plan Review is Crucial!
Always meticulously review the output of `terraform plan` before applying. Understand exactly what resources will be created, modified, or destroyed to prevent accidental data loss or unwanted changes.
:::

## Terraform State <Badge type="danger" text="Important!" />

Terraform records the infrastructure it manages in a **state file** (usually `terraform.tfstate`).

- **Mapping:** Connects your configuration resources to real-world objects.
- **Metadata:** Stores resource dependencies and attributes.
- **Performance:** Improves planning for large infrastructures.

::: danger State File Sensitivity
The state file can contain sensitive information. **Do not commit `terraform.tfstate` directly to Git** or share it publicly. Use `.gitignore` to exclude it!
:::

::: tip Remote Backends
For team collaboration and better security/reliability, use **remote backends** (like AWS S3, Azure Blob Storage, Google Cloud Storage, HashiCorp Cloud, or GitLab Managed Terraform State) to store the state file remotely, manage locking, and prevent conflicts.

```hcl
# Example backend configuration (main.tf or backend.tf)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-name"
    key            = "path/to/my/project/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "my-terraform-lock-table" # For state locking
  }
}
```

:::

## Providers, Resources, Variables & Modules

### Providers <Badge type="info" text="Plugins" />

Providers are plugins that enable Terraform to interact with specific APIs (cloud providers, SaaS services, etc.). You declare required providers in your configuration.

```hcl
# Example: Requiring the Hetzner Cloud provider (versions.tf)
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.4" # Specify version constraint
    }
  }
}

# Configure the provider (e.g., main.tf or provider.tf)
provider "hcloud" {
  # Token can be set via environment variable HCLOUD_TOKEN
  # token = var.hcloud_token
}
```

### Resources <Badge type="tip" text="Building Blocks" />

Resources are the fundamental elements of your infrastructure (e.g., a virtual machine, a DNS record, a database).

```hcl
# Example: Define an Hetzner Cloud server (main.tf)
resource "hcloud_server" "web_server" {
  name        = "my-web-server"
  server_type = "cx11" # Smallest server type
  image       = "ubuntu-22.04"
  location    = "fsn1" # Falkenstein location
  # ... other configurations like ssh_keys, network, etc.
}
```

### Variables <Badge type="tip" text="Inputs" />

Variables allow you to parameterize your configurations, making them more flexible and reusable.

```hcl
# Define a variable (variables.tf)
variable "server_type" {
  description = "The type of server to provision"
  type        = string
  default     = "cx11"
}

# Use the variable in a resource (main.tf)
resource "hcloud_server" "web_server" {
  # ...
  server_type = var.server_type # Reference the variable
  # ...
}
```

### Modules <Badge type="tip" text="Reusability" />

Modules are containers for multiple resources that are used together. They help organize configurations and promote reuse.

```hcl
# Using a module (main.tf)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws" # Source from Terraform Registry
  version = "5.1.1"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  # ... other module inputs
}
```

---

This overview covers the essentials of Terraform. For deeper dives, consult the official [HashiCorp Terraform Documentation](https://developer.hashicorp.com/terraform/docs).
