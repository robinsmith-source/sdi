# Setting up DNS

> This chapter covers setting up and managing DNS records for your projects, including manual updates, automated provisioning with Terraform, and enabling HTTPS with Caddy.

## Prerequisites

Before you begin, ensure you have:

- A working Terraform project capable of creating a Hetzner Cloud server like in [Exercise 14](/chapters/04-server-initialization#exercise-14)
- Access to your group's DNS zone and HMAC secret key.
- A basic understanding of DNS concepts and tools like `dig` and `nsupdate`.

## External Resources

For more in-depth information about DNS management:

- [BIND9 Documentation](https://bind9.readthedocs.io/) - Official BIND9 documentation
- [DNS Update Protocol (RFC 2136)](https://datatracker.ietf.org/doc/html/rfc2136)
- [Caddy Documentation](https://caddyserver.com/docs/) - Caddy web server configuration

::: tip
For comprehensive information about DNS concepts, see [DNS Concepts](/knowledge/dns).
:::

## 1. Understanding Your DNS Zone

Each group is assigned a dedicated subdomain (zone) on the `ns1.hdm-stuttgart.cloud` nameserver. For example, group 10's zone is `g10.sdi.hdm-stuttgart.cloud`. You can view all records in your zone by performing a zone transfer with `dig`:

```sh
# Export your HMAC key as an environment variable
export HMAC="hmac-sha512:g10.key:<YOUR_SECRET_KEY>"

# Perform a full zone transfer (AXFR)
dig @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g10.sdi.hdm-stuttgart.cloud
```

## 2. Manual DNS Record Management

You can add, update, or delete DNS records using the `nsupdate` command-line tool, which sends dynamic DNS updates to the nameserver.

### 2.1. Adding and Deleting Records

To add a new `A` record, start an `nsupdate` session, specify the server and your update command:

```sh
# Start an interactive nsupdate session with your HMAC key
nsupdate -y $HMAC

# Specify the DNS server
server ns1.hdm-stuttgart.cloud

# Add an A record with a 10-second TTL pointing to the server's IP address
update add www.g10.sdi.hdm-stuttgart.cloud 10 A <YOUR_SERVER_IP>

# Send the update and exit
send
quit
```

To modify a record, you must first delete the old one and then add the new one.

## 3. Enhancing Your Web Server with DNS and HTTPS [Exercise 18] {#exercise-18}

In this exercise, you will assign a DNS name to a web server and enable automatic HTTPS using the Caddy web server. Caddy will handle obtaining and renewing TLS certificates from Let's Encrypt for you.

### 3.1. DNS and Web Server Configuration

First, add an `A` record for your web server that points to its IP address, as shown in the section above.

Next, use a Cloud-Init configuration to install and set up Caddy. The `Caddyfile` is the main configuration file for Caddy. Here, you configure it to serve files from `/var/www/html` for your domain.

::: code-group

```yaml [tpl/userData.yml]
#cloud-config
# ... (user setup, package updates, etc.)
packages:
  - caddy
  # ... (other packages like fail2ban)

write_files:
  - path: /etc/caddy/Caddyfile
    content: |
      www.g10.sdi.hdm-stuttgart.cloud {
        root * /var/www/html
        file_server
      }

runcmd:
  - mkdir -p /var/www/html
  - echo "<h1>Hello from Caddy!</h1>" > /var/www/html/index.html
  - systemctl enable --now caddy
  # ... (other run commands)
```

:::

After applying this configuration, Caddy will automatically a TLS certificate for your domain and serve your website over HTTPS.

The `Caddyfile` is designed to be simple and human-readable. In this configuration:

- `www.g10.sdi.hdm-stuttgart.cloud`: This is the address of your site. Caddy will automatically provision a certificate for this domain.
- `root * /var/www/html`: This directive tells Caddy that the root directory for all requests (`*`) is `/var/www/html`.
- `file_server`: This enables Caddy's static file server, which is necessary to serve the `index.html` file.

::: details Why use the staging environment?
The staging environment (`acme-staging-v02.api.letsencrypt.org/directory`) is used here because it has much higher rate limits and issues certificates that aren't trusted by browsers. This makes it perfect for testing and learning without hitting production limits or affecting your ability to get real certificates later.
:::

Also make sure to extend the firewall rules to allow HTTPS traffic.

::: code-group

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "hcloud_firewall" "firewall" {
  name = "firewall-ssh-http"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol = "tcp"
    port = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction = "in"
    protocol = "tcp"
    port = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
```

:::

::: warning
Your browser will show a warning about the certificate being untrusted. This is because the staging environment issues certificates that aren't trusted by browsers.
:::

## 4. Creating DNS Records with Terraform [Exercise 19] {#exercise-19}

In this exercise, you will manage DNS records declaratively using Terraform. This approach allows you to define your DNS setup in code, making it versionable and repeatable.

### 4.1. Configuration with Validation

You will create a flexible configuration that defines a primary `A` record for a server and several `CNAME` aliases. Therefore you will need to make the following changes to your files:

::: code-group

```hcl [config.auto.tfvars]
server_ip     = "1.2.3.4"
dns_zone      = "g10.sdi.hdm-stuttgart.cloud"
server_name   = "workhorse"
server_aliases = ["www", "mail"]
```

```hcl [variables.tf]
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "dns_secret" {
  description = "DNS HMAC-SHA512 key secret for DNS updates"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "dns_zone" {
  description = "The base domain for DNS records"
  type        = string
  nullable    = false
}

variable "server_name" {
  description = "The canonical name of the server"
  type        = string
  nullable    = false
}

variable "server_ip" {
  description = "The IP address for the A records"
  type        = string
  nullable    = false
}

variable "server_aliases" {
  type    = list(string)
  default = []
  validation {
    condition     = length(distinct(var.server_aliases)) == length(var.server_aliases) && !contains(var.server_aliases, var.server_name)
    error_message = "Aliases must be unique and must not match the server_name."
  }
}
```

:::

The `validation` blocks in the variable definition help prevent misconfigurations before Terraform attempts to apply the changes.
In the `main.tf` file you will need to add the following resources:

::: code-group

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "dns_a_record_set" "server_a" { // [!code focus:40] [!code ++:6]
  zone      = "${var.dns_zone}."
  name      = var.server_name
  addresses = [var.server_ip]
  ttl       = 10
}

resource "dns_a_record_set" "server_a_root" {  // [!code ++:5]
  zone      = "${var.dns_zone}."
  addresses = [var.server_ip]
  ttl       = 10
}

resource "dns_cname_record" "server_aliases" {  // [!code ++:8]
  count      = length(var.server_aliases)
  zone       = "${var.dns_zone}."
  name       = var.server_aliases[count.index]
  cname      = "${var.server_name}.${var.dns_zone}."
  ttl        = 10
  depends_on = [dns_a_record_set.server_a, hcloud_server.debian_server]
}
```

:::

After applying this configuration, you will have a server with a primary `A` record for the canonical name and `CNAME` records for the aliases.

## 5. Creating a Host with Corresponding DNS Entries [Exercise 20] {#exercise-20}

This exercise combines server creation and DNS record management. A key improvement here is to use the server's fully qualified domain name (FQDN) in the generated helper scripts instead of its IP address.

### 5.1. Terraform Configuration

You will create a server and automatically generate DNS records for it. The server's IP address will be used to create an `A` record, and the FQDN will be used in the helper scripts.

::: code-group

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "hcloud_server" "debian_server" { // [!code focus:40]
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "dns_a_record_set" "server_a" {
  zone      = "${var.dns_zone}."
  name      = var.server_name
  addresses = [var.server_ip]
  ttl       = 10
}

resource "dns_a_record_set" "server_a_root" {
  zone      = "${var.dns_zone}."
  addresses = [var.server_ip]
  ttl       = 10
}

resource "dns_cname_record" "server_aliases" {
  count      = length(var.server_aliases)
  zone       = "${var.dns_zone}."
  name       = var.server_aliases[count.index]
  cname      = "${var.server_name}.${var.dns_zone}."
  ttl        = 10
  depends_on = [dns_a_record_set.server_a, hcloud_server.debian_server]
}

module "ssh_wrapper" {
  source     = "../../modules/ssh-wrapper"
  login_user  = "devops"
  hostname   = "${var.server_name}.${var.dns_zone}" // [!code ++]
  public_key = tls_private_key.host.public_key_openssh
  depends_on = [dns_a_record_set.server_a] // [!code ++]
}
```

:::

This makes your helper scripts more robust, as they are no longer tied to a specific IP address that might change.

In your `ssh-wrapper` module, you will need to adjust the script generation to use the FQDN instead of the IP address:

::: code-group

```hcl [ssh-wrapper/main.tf]
locals { // [!code ++:3]
  target_host = var.hostname != null && var.hostname != "" ? var.hostname : var.ipv4Address
}

resource "local_file" "known_hosts" {
  content         = "${local.target_host} ${var.public_key}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh.sh", {
    host = var.ipv4Address // [!code --]
    host = local.target_host // [!code ++]
    user = var.login_user
  })
  filename        = "bin/ssh"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}

resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp.sh", {
    host = var.ipv4Address // [!code --]
    host = local.target_host // [!code ++]
    user = var.login_user
  })
  filename        = "bin/scp"
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}
```

```hcl [ssh-wrapper/variables.tf]
variable "ipv4Address" {
  description = "The IPv4 address of the server"
  type        = string
  nullable    = false // [!code --]
  nullable    = true // [!code ++]
  default     = null // [!code ++]
}
```

:::

This allows you to optionally pass a hostname to the module, which will be used in the generated scripts. If no hostname is provided, it will fall back to using the server's IPv4 address.

## 6. Creating a Fixed Number of Servers [Exercise 21] {#exercise-21}

This exercise uses Terraform's `count` meta-argument to deploy a configurable number of servers, each with its own unique DNS entry and set of helper scripts.

### 6.1. Terraform Configuration

You will define the number of servers to create in a variable. The `count` argument is then used to loop through and create each resource. You will use `count.index` to give each resource a unique name and to create a separate directory for each server's generated files.

::: code-group

```hcl [config.auto.tfvars]
dns_zone         = "g10.sdi.hdm-stuttgart.cloud"
server_name = "work"
server_aliases   = ["www", "mail"]
server_count     = 2 // [!code ++]
```

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "hcloud_server" "debian_server" { // [!code focus:60]
  count        = var.server_count // [!code ++]
  name         = "debian-server" // [!code --]
  name         = "${var.server_name}-${count.index + 1}" // [!code ++]
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content // [!code --]
  user_data    = local_file.user_data[count.index].content // [!code ++]
}

resource "dns_a_record_set" "server_a" {
  count     = var.server_count // [!code ++]
  zone      = "${var.dns_zone}."
  name      = "${var.server_name}" // [!code --]
  name      = "${var.server_name}-${count.index + 1}" // [!code ++]
  addresses = [var.server_ip] // [!code --]
  addresses = [hcloud_server.debian_server[count.index].ipv4_address] // [!code ++]
  ttl       = 10
}

resource "dns_a_record_set" "server_a_root" {
  count     = var.server_count // [!code ++]
  zone      = "${var.dns_zone}."
  addresses = [var.server_ip] // [!code --]
  addresses = [hcloud_server.debian_server[count.index].ipv4_address] // [!code ++]
  ttl       = 10
}

resource "dns_cname_record" "server_aliases" {
  count      = length(var.server_aliases)
  zone       = "${var.dns_zone}."
  name       = var.server_aliases[count.index]
  cname      = "${var.server_name}.${var.dns_zone}."
  ttl        = 10
  depends_on = [dns_a_record_set.server_a, hcloud_server.debian_server]
}

module "ssh_wrapper" {
  count      = var.server_count // [!code ++]
  source     = "../../modules/ssh-wrapper"
  login_user  = "devops"
  hostname   = "${var.server_name}.${var.dns_zone}" // [!code --]
  hostname   = "${var.server_name}-${count.index + 1}.${var.dns_zone}" // [!code ++]
  public_key = tls_private_key.host.public_key_openssh // [!code --]
  public_key = tls_private_key.host[count.index].public_key_openssh // [!code ++]
}
```

```hcl [variables.tf]
# ... Other non-relevant variable definitions ...
variable "server_name" { // [!code focus:15]
  description = "The canonical name of the server"
  type        = string
  nullable    = false
}

variable "server_count" { // [!code ++:5]
  description = "The number of servers to create"
  type        = number
  default     = 2
}
```

:::

::: tip
You have to add the `target_host` to the `ssh-wrapper` module to avoid a overwrite of the `ssh` and `scp` scripts as well as the `known_hosts` file, when cycling over multiple servers.

::: code-group

```hcl [ssh-wrapper/main.tf]
# ... Other non-relevant resources for this exercise ...
resource "local_file" "known_hosts" {
  content         = "${local.target_host} ${var.public_key}"
  filename        = "gen/known_hosts" // [!code --]
  filename        = "gen/known_hosts_${local.target_host}" // [!code ++]
  file_permission = "644"
}

resource "local_file" "ssh_script" {
  content = templatefile("${path.module}/tpl/ssh.sh", {
    host = var.ipv4Address // [!code --]
    host = local.target_host // [!code ++]
    user = var.login_user
  })
  filename        = "bin/ssh" // [!code --]
  filename        = "bin/ssh_${local.target_host}" // [!code ++]
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}

resource "local_file" "scp_script" {
  content = templatefile("${path.module}/tpl/scp.sh", {
    host = var.ipv4Address // [!code --]
    host = local.target_host // [!code ++]
    user = var.login_user
  })
  filename        = "bin/scp" // [!code --]
  filename        = "bin/scp_${local.target_host}" // [!code ++]
  file_permission = "755"

  depends_on = [local_file.known_hosts]
}
```

```hcl [ssh-wrapper/tpl/scp.sh]
#!/usr/bin/env bash
GEN_DIR=$(dirname "$0")/../gen

if [ $# -lt 2 ]; then
   echo usage: ./bin/scp <arguments>
else
   scp -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${host} $@ # [!code --]
   scp -o UserKnownHostsFile="$GEN_DIR/known_hosts_${host}" ${user}@${host} $@ # [!code ++]
fi
```

```hcl [ssh-wrapper/tpl/ssh.sh]
#!/usr/bin/env bash
GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" ${user}@${host} "$@" # [!code --]
ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts_${host}" ${user}@${host} "$@" # [!code ++]
```

:::

After applying using `terraform apply`, you will have two new directories, `work-1` and `work-2`, each containing `bin` and `gen` subdirectories with the corresponding scripts and `known_hosts` file for each server.
