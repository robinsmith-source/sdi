# Cloud-init

> Cloud-init is a widely-used industry standard method for cloud instance initialization. It automatically configures cloud instances during their first boot, allowing you to install packages, create users, configure services, and run custom scripts without manual intervention.

## Core Concepts {#core-concepts}

Cloud-init operates by reading configuration data (often called "user data") provided by the cloud platform during instance creation. It processes this data in distinct stages during the boot process.

### Key Concepts Explained

::: details User Data
The configuration input provided to Cloud-init. This data tells Cloud-init what actions to perform. It can be supplied in various formats, with `#cloud-config` being the most common. Cloud platforms provide mechanisms to pass this data during instance launch.
:::

::: details Cloud-config Format (`#cloud-config`) <Badge type="tip" text="YAML" />
A YAML-based format starting with `#cloud-config` or `#!cloud-config`. It's the most popular way to structure user data, allowing configurations via various modules.
:::

::: details Cloud-init Modules
Cloud-init operates through modules, each responsible for a specific configuration task. Common modules include:

- `packages`: Install, upgrade, or remove software packages
- `runcmd`: Execute arbitrary shell commands late in the boot process
- `users`: Create or modify users and groups, set passwords, and add SSH keys
- `write_files`: Create or append to files on the filesystem
- `ssh`: Configure SSH server options
- `apt`/`yum`: Configure package manager sources
- `mounts`: Define filesystem mounts
  :::

::: details Execution Stages
Cloud-init runs tasks in specific stages during the boot process (network, config, final). Understanding the order can be important for dependencies (e.g., ensuring network is up before downloading a file).
:::

::: details Vendor Data
Some cloud providers might supply additional "vendor data" alongside user data, often used for platform-specific configurations.
:::

## Essential Commands <Badge type="tip" text="Core CLI" />

### Example Cloud-init Configurations

```yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
```

```yaml
#cloud-config
users:
  - name: devops
    groups: [sudo]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEXAMPLEKEY... user@example.com
```

```yaml
#cloud-config
write_files:
  - path: /etc/motd
    permissions: "0644"
    content: |
      Welcome to this Cloud-init configured server!
      Managed by DevOps Team.
```

```yaml
#cloud-config
packages:
  - git
  - python3-pip
write_files:
  - path: /opt/app/config.ini
    content: |
      [Database]
      host = localhost
      port = 5432
runcmd:
  - pip3 install flask
  - git clone https://github.com/example/my-app.git /opt/app/repo
  - echo "Setup complete at $(date)" > /opt/app/setup.log
```

## Best Practices

- Use simple, modular configurations and add complexity gradually
- Design `runcmd` scripts to be idempotent if possible
- Store your Cloud-init configs in version control
- Test configurations on ephemeral instances and check logs (`/var/log/cloud-init.log`)
- Avoid embedding sensitive data directly; use secure methods
- Prefer built-in modules over complex shell scripts

## Common Use Cases

- **Package Management**: Install essential tools and dependencies
- **User & Group Management**: Create users, set up SSH keys
- **Running Commands**: Execute setup scripts, configure services
- **Writing Files**: Create config files, set environment variables
- **SSH Configuration**: Harden SSH settings
- **Network Configuration**: Set static IPs or configure interfaces
- **Storage Setup**: Format and mount additional volumes

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details Cloud-init Not Running as Expected
Check for syntax errors in your user data. Review logs: `/var/log/cloud-init.log` and `/var/log/cloud-init-output.log`. Ensure the cloud platform is passing user data correctly.
:::

::: details Package Installation Fails
Confirm package names are correct for the OS. Check network connectivity from the instance. Verify package repository configuration.
:::

::: details User/SSH Key Issues
Ensure SSH keys are in the correct format. Check file permissions on `/home/username/.ssh/authorized_keys`. Verify user creation and group assignments.
:::

::: details File Writing Problems
Check file paths and permissions. Ensure directories exist before writing files. Verify content formatting and encoding.
:::
