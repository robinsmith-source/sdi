# Cloud-init <Badge text="Instance Initialization" />

Cloud-init is the industry standard multi-distribution method for cross-platform cloud instance initialization. It allows you to define configurations and run scripts on a cloud server during its very first boot, automating the initial setup process.

::: info Purpose
Cloud-init bridges the gap between provisioning a base OS image and having a fully configured, ready-to-use server instance. It handles tasks that need to run *inside* the instance after it boots for the first time.
:::

## Core Workflow & Concepts {#core-workflow}

Cloud-init operates by reading configuration data (often called "user data") provided by the cloud platform during instance creation.

1.  **Provide User Data:** When launching a cloud instance (e.g., via a web UI, API, or IaC tool like Terraform), you supply configuration data in a format Cloud-init understands.
2.  **First Boot Execution:** Upon the instance's initial boot, Cloud-init detects the provided user data.
3.  **Process Configuration:** It parses the user data and executes the defined configurations and commands in distinct stages.
4.  **Completion:** Once finished, Cloud-init typically disables itself to prevent re-running on subsequent boots.

### Key Concepts Explained

::: details User Data
The configuration input provided to Cloud-init. This data tells Cloud-init what actions to perform. It can be supplied in various formats, with `#cloud-config` being the most common. Cloud platforms provide mechanisms to pass this data during instance launch.
:::

::: details Cloud-config Format (`#cloud-config`) <Badge type="tip" text="YAML" />
A YAML-based format starting with `#cloud-config` or `#!cloud-config`. It's the most popular way to structure user data, allowing configurations via various modules.
:::

::: details Cloud-init Modules
Cloud-init operates through modules, each responsible for a specific configuration task. User data directives map to these modules. Common modules include:
*   `packages`: Install, upgrade, or remove software packages.
*   `runcmd`: Execute arbitrary shell commands late in the boot process.
*   `users`: Create or modify users and groups, set passwords, and add SSH keys.
*   `write_files`: Create or append to files on the filesystem.
*   `ssh`: Configure SSH server options.
*   `apt`/`yum`: Configure package manager sources.
*   `mounts`: Define filesystem mounts.
:::

::: details Execution Stages
Cloud-init runs tasks in specific stages during the boot process (network, config, final). Understanding the order can be important for dependencies (e.g., ensuring network is up before downloading a file). See the official Cloud-init documentation for stage details.
:::

::: details Vendor Data
Some cloud providers might supply additional "vendor data" alongside user data, often used for platform-specific configurations.
:::

## Common Features & Use Cases

Cloud-init can automate a wide range of initial setup tasks:

- **Package Management:** Installing essential tools (`git`, `vim`, `docker`), web servers (`nginx`, `apache`), or application dependencies.
- **User & Group Management:** Creating service accounts or administrative users, setting up sudo privileges, and distributing SSH public keys for access.
- **Running Commands:** Executing setup scripts, configuring services, cloning repositories, or performing initial data seeding.
- **Writing Files:** Creating configuration files (e.g., `/etc/nginx/sites-available/default`), setting environment variables, or writing application settings.
- **SSH Configuration:** Hardening SSH daemon settings (disabling password auth, changing port), managing host keys.
- **Network Configuration:** Setting static IPs or configuring network interfaces (though often handled by the cloud platform).
- **Storage Setup:** Formatting and mounting additional volumes.

## Examples

Here are some practical examples using the `#cloud-config` format:

**1. Update Packages and Install Nginx:**

This example updates all packages and installs the `nginx` web server.

````yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
````

**2. Create a User and Add SSH Key:**

This creates a user named `devops`, adds them to the `sudo` group, grants passwordless sudo, and authorizes an SSH public key for login.

````yaml
#cloud-config
users:
  - name: devops
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEXAMPLEKEY... user@example.com
````

**3. Write a Configuration File:**

This example writes a simple text file to `/etc/motd` (Message of the Day).

````yaml
#cloud-config
write_files:
  - path: /etc/motd
    permissions: '0644'
    content: |
      Welcome to this Cloud-init configured server!
      Managed by DevOps Team.
````

**4. Combining Multiple Modules:**

This example combines package installation, file writing, and command execution.

````yaml
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
````

## Best Practices

- **Start Simple:** Begin with basic configurations and add complexity gradually.
- **Idempotency:** Design `runcmd` scripts to be safe to run multiple times if possible, although Cloud-init aims to run only once.
- **Modularity:** Use YAML anchors or includes (if supported by your templating method) to keep configurations organized.
- **Version Control:** Store your Cloud-init configurations (`#cloud-config` files or templates) in Git alongside your infrastructure code.
- **Testing:** Test configurations thoroughly, ideally on ephemeral instances. Cloud-init logs (`/var/log/cloud-init.log` and `/var/log/cloud-init-output.log`) are crucial for debugging.
- **Security:** Be cautious with `runcmd`. Avoid embedding sensitive data directly; use secure methods provided by the cloud platform or tools like HashiCorp Vault if necessary. Ensure correct file permissions when using `write_files`.
- **Understand Execution Order:** Be aware of Cloud-init stages if your commands have dependencies (e.g., needing packages installed before running a command that uses them).
- **Use Official Modules:** Prefer using built-in modules (`users`, `packages`, `write_files`) over complex `runcmd` scripts where possible, as modules are often more robust and platform-aware.

---

Cloud-init is a powerful tool for automating instance setup. Refer to the [Official Cloud-init Documentation](https://cloudinit.readthedocs.io/) for comprehensive details on modules, formats, and advanced features.