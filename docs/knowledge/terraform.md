# Terraform

> Terraform is a powerful Infrastructure as Code (IaC) tool by HashiCorp. It allows you to define, provision, and manage cloud and on-prem infrastructure using a declarative configuration language called HCL (HashiCorp Configuration Language).

## Core Concepts {#core-concepts}

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

```sh
# Initialize a Terraform project
terraform init

# Format and validate configuration
terraform fmt
terraform validate

# Preview changes
terraform plan
terraform plan -out=tfplan

# Apply changes
terraform apply
terraform apply tfplan
terraform apply -auto-approve

# Destroy resources
terraform destroy
terraform destroy -auto-approve
```

## Best Practices

- Always review `terraform plan` output before applying
- Use remote backends for state storage in teams
- Never commit state files to version control
- Use modules for reusability and organization
- Parameterize with variables and outputs
- Use version constraints for providers and modules

## Common Use Cases

- Provisioning cloud infrastructure (VMs, networks, databases)
- Managing DNS, storage, and SaaS resources
- Automating multi-cloud and hybrid-cloud deployments
- Creating reusable infrastructure modules

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details State File Issues

- Never commit `terraform.tfstate` to Git
- Use remote backends for collaboration
- If state is lost, resources may be orphaned or recreated
  :::

::: details Provider Authentication Errors

- Ensure credentials are set (env vars, config files, etc.)
- Check provider documentation for required setup
  :::

::: details Plan/Apply Fails

- Validate configuration syntax
- Check for resource naming conflicts
- Review error messages for hints
  :::
