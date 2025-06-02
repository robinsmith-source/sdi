# Terraform Modules <Badge type="info" text="IaC" />

> Terraform modules are reusable, self-contained packages of Terraform configurations that manage a collection of related infrastructure resources. They enable you to organize, encapsulate, and share infrastructure code, promoting best practices like DRY (Don't Repeat Yourself) and modular design.

::: info Purpose
Terraform modules enable:
- Reusability and sharing of infrastructure code
- Organization and abstraction of complex setups
- Standardization and collaboration across teams
:::

## Core Concepts {#core-concepts}

### What is a Module?
A Terraform module is a directory containing `.tf` files. Every Terraform configuration is technically a module (the "root module").

### Module Types
- **Root Module:** The main working directory where you run Terraform commands
- **Child Modules:** Modules called by other modules
- **Published Modules:** Modules shared via the Terraform Registry or other repositories

::: details Module Components
- **Input Variables:** Parameters that customize module behavior
- **Output Values:** Return values that other modules can use
- **Resources:** The infrastructure components the module manages
- **Data Sources:** Information fetched from existing infrastructure
:::

::: details Module Sources
Modules can be sourced from:
- Local paths (relative or absolute)
- Terraform Registry (public or private)
- Git repositories (GitHub, GitLab, etc.)
- HTTP URLs
- S3 buckets
:::

## Essential Commands <Badge type="tip" text="Core CLI" />

```hcl
# Using a local module
module "web_server" {
  source = "./modules/hcloud-server"
  server_name = "production-web"
  server_type = "cx21"
  location    = "fsn1"
  environment = "prod"
}

# Using a registry module
module "network" {
  source  = "hetznercloud/network/hcloud"
  version = "~> 1.0"
  name     = "my-network"
  ip_range = "10.0.0.0/16"
}

# Pin to specific version
module "network" {
  source  = "hetznercloud/network/hcloud"
  version = "1.2.3"
}

# From Git repository
module "web_server" {
  source = "git::https://github.com/company/terraform-modules.git//hcloud-server?ref=v1.2.0"
}
```

```sh
# Initialize and download modules
terraform init
# Get/update modules
terraform get
# Show module tree
terraform providers
# Validate module configuration
terraform validate
```

## Best Practices

- Use modules for all but the simplest configurations
- Keep modules focused and well-documented
- Use version constraints for modules
- Prefer published/official modules when possible
- Store custom modules in version control

## Common Use Cases

- Standardizing cloud server builds
- Networking and VPC setup
- Reusable security group/firewall definitions
- Multi-environment deployments (dev, staging, prod)

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details Module Not Found
- Check the `source` path or URL
- Ensure the module is downloaded with `terraform init`
:::

::: details Input Variable Errors
- Ensure all required variables are set
- Check variable types and defaults
:::

::: details Output/Dependency Issues
- Reference outputs correctly (e.g., `module.name.output`)
- Check for circular dependencies
:::

---

For more, see the [Terraform Modules Documentation](https://developer.hashicorp.com/terraform/language/modules).
