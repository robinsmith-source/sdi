# Setting up Certificates

> This guide covers SSL/TLS certificate management with Terraform and the ACME provider, including automated certificate generation, DNS challenges, and web server deployment with proper certificate configuration.

## Prerequisites

Before you begin, ensure you have:

- A working Terraform project capable of creating a Hetzner Cloud server and managing DNS records.
- Your group's HMAC secret key for DNS updates.
- A basic understanding of SSL/TLS certificates.

## External Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [ACME Terraform Provider](https://registry.terraform.io/providers/vancluever/acme/latest/docs)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)

::: tip
For comprehensive information about Certificate concepts, see [Certificate Concepts](/knowledge/certificates).
:::

## 1. Automating Certificate Generation with Terraform

Terraform's `acme` provider allows you to automate the entire lifecycle of SSL/TLS certificates, from creation and validation to renewal. It interacts with ACME-compatible certificate authorities like Let's Encrypt.

### 1.1. Provider Configuration

First, configure the `acme` provider. It is crucial to use the **staging URL** for development and testing to avoid hitting Let's Encrypt's strict rate limits.

::: code-group

```hcl [providers.tf]
provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
```

:::

::: tip
You can switch to the production URL once you have verified your configuration and are ready to issue real certificates:

```hcl
provider "acme" {
    server_url = "https://acme-v02.api.letsencrypt.org/directory
}

This will also remove the browser warning with untrusted certificates.
```

:::

::: danger Provider Version
Due to a known issue, you must use `acme` provider version `v2.13.1` or newer. It is best to not pin the version to automatically receive the latest stable release.

```hcl
terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
  }
}
```

:::

### 1.2. Generating a Certificate [Exercise 22] {#exercise-22}

To generate a certificate, you need an account key and a certificate request. The following configuration creates a wildcard certificate for a primary domain and several alternative names using a DNS challenge for validation.

::: code-group

```hcl [main.tf]
resource "tls_private_key" "host" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" { // [!code ++:4]
  account_key_pem = tls_private_key.host.private_key_pem
  email_address   = var.email_address
}

resource "acme_certificate" "certificate" {  // [!code ++:17]
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "*.${var.dns_zone}"
  subject_alternative_names = [
    var.dns_zone,
  ]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = var.name_server
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "g10.key."
      RFC2136_TSIG_SECRET    = var.dns_secret
    }
  }
}

resource "local_file" "private_key_pem" { // [!code ++:4]
  content  = acme_certificate.certificate.private_key_pem
  filename = "${path.module}/gen/private.pem"
}

resource "local_file" "certificate_pem" { // [!code ++:4]
  content  = acme_certificate.certificate.certificate_pem
  filename = "${path.module}/gen/certificate.pem"
}
```

```hcl [variables.tf]
# ... Other non-relevant variables for this exercise ...
variable "email_address" { // [!code focus:4]
  description = "Email address for Let's Encrypt registration"
  type        = string
}
```

```hcl [output.tf]
# ... Other non-relevant outputs for this exercise ...
output "certificate_pem" { // [!code focus:10]
  value     = acme_certificate.certificate.certificate_pem
  sensitive = true
}

output "private_key_pem" {
  value     = acme_certificate.certificate.private_key_pem
  sensitive = true
}
```

:::

This configuration generates a private key using the `tls_private_key` resource, registers an ACME account with the provided email address, requests a wildcard certificate for the specified domain and its subdomains, uses a DNS challenge to validate domain ownership via RFC 2136, and saves the generated certificate and private key to local files.

## 2. Testing Your Web Certificate [Exercise 23] {#exercise-23}

In this exercise, you will deploy the generated certificate to an Nginx web server. The goal is to create a server, point multiple DNS names to it, and configure Nginx to serve HTTPS traffic for those names.

### 2.1. Server and DNS Configuration

Your Terraform configuration should create a server and the corresponding DNS records. Use a variable to manage the list of hostnames.

::: code-group

```hcl [config.auto.tfvars]
dns_zone      = "g10.sdi.hdm-stuttgart.cloud"
name_server   = "ns1.sdi.hdm-stuttgart.cloud"
server_names  = ["www", "mail"]
email_address = "rs141@hdm-stuttgart.de"
```

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "tls_private_key" "host" {
  algorithm = "RSA"
}

resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    login_user          = "root"
    public_key_robin    = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key     = indent(4, tls_private_key.host.private_key_openssh)
    server_names_string = join(" ", [for name in var.server_names : "${name}.${var.dns_zone}"]) // [!code ++:4]
    dns_zone            = var.dns_zone
    certificate_pem     = indent(6, acme_certificate.certificate.certificate_pem)
    private_key_pem     = indent(6, acme_certificate.certificate.private_key_pem)
  })
  filename = "gen/userData.yml"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.host.private_key_pem
  email_address   = var.email_address
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "*.${var.dns_zone}"
  subject_alternative_names = [
    var.dns_zone,
  ]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = var.name_server
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "g10.key."
      RFC2136_TSIG_SECRET    = var.dns_secret
    }
  }
}

resource "dns_a_record_set" "root_domain" {
  zone      = "${var.dns_zone}."
  addresses = [hcloud_server.debian_server.ipv4_address]
  ttl       = 10
}

resource "dns_cname_record" "aliases" {
  count = length(var.server_names)
  zone  = "${var.dns_zone}."
  name  = var.server_names[count.index]
  cname = "${var.dns_zone}."
  ttl   = 10
}
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

variable "server_names" {
  description = "List of subdomain names to create"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "name_server" {
  description = "The DNS nameserver for ACME DNS challenges"
  type        = string
  nullable    = false
}

variable "email_address" {
  description = "Email address for Let's Encrypt registration"
  type        = string
  nullable    = false
}

```

:::

### 2.2. Web Server Setup with Cloud-Init

Use Cloud-Init to install Nginx and deploy the certificate. The `write_files` module will place the certificate and private key (generated locally by Terraform) onto the server.

::: code-group

```hcl [main.tf]
# In your main.tf, prepare the user_data content
resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    certificate_pem = acme_certificate.cert.certificate_pem,
    private_key_pem = acme_certificate.cert.private_key_pem,
    fqdn            = var.dns_zone
  })
  filename = "gen/userData.yml"
}
```

```yml [tpl/userData.yml]
#cloud-config
users:
  - name: ${login_user}
    groups: [sudo]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]

package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
  - nginx

write_files: // [!code ++:24]
  - path: /etc/ssl/certs/live.pem
    content: |
      ${certificate_pem}
  - path: /etc/ssl/private/live.key
    content: |
      ${private_key_pem}
    permissions: "0600"
  - path: /etc/nginx/sites-available/default
    content: |
      server {
          listen 80 default_server;
          listen [::]:80 default_server;
          listen 443 ssl default_server;
          listen [::]:443 ssl default_server;

          server_name ${dns_zone} ${server_names_string};

          ssl_certificate /etc/ssl/certs/live.pem;
          ssl_certificate_key /etc/ssl/private/live.key;

          root /var/www/html;
          index index.html index.htm index.nginx-debian.html;
      }

runcmd: // [!code ++:4]
  - systemctl enable nginx
  - systemctl restart nginx
  - nginx -t
```

:::

### 2.3. Verification

After applying the configuration, test that Nginx is running correctly (`nginx -t`) and restart it. Then, access `https://g10.sdi.hdm-stuttgart.cloud` in a browser. You may see a warning because the certificate is from the Let's Encrypt staging environment. Inspect the certificate to verify it was issued for your domains.

## 3. Unified Infrastructure Deployment [Exercise 24] {#exercise-24}

The final step is to combine certificate generation, DNS configuration, and server provisioning into a single, unified Terraform configuration. The examples from the previous exercises, when put together in one project, achieve this goal.
Therefore you'll re-create this configuration with Caddy instead, which makes it a lot simpler.

::: code-group

```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "local_file" "user_data" { // [!code focus:40]
  content = templatefile("tpl/userData.yml", {
    login_user          = "devops"
    public_key_robin    = hcloud_ssh_key.user_ssh_key.public_key
    server_names_string = join(" ", [for name in var.server_names : "${name}.${var.dns_zone}"]) // [!code --]
    server_names_string = join(" ", concat([var.dns_zone], [for name in var.server_names : "${name}.${var.dns_zone}"])) // [!code ++]
    dns_zone            = var.dns_zone
    certificate_pem     = indent(6, acme_certificate.certificate.certificate_pem) // [!code --]
    private_key_pem     = indent(6, acme_certificate.certificate.private_key_pem) // [!code --]
  })
  filename = "gen/userData.yml"
}

resource "acme_registration" "reg" { // [!code --:4]
  account_key_pem = tls_private_key.host.private_key_pem
  email_address   = var.email_address
}

resource "acme_certificate" "certificate" { // [!code --:26]
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = "*.${var.dns_zone}"
  subject_alternative_names = [
    var.dns_zone,
  ]

  dns_challenge {
    provider = "rfc2136"
    config = {
      RFC2136_NAMESERVER     = var.name_server
      RFC2136_TSIG_ALGORITHM = "hmac-sha512"
      RFC2136_TSIG_KEY       = "g10.key."
      RFC2136_TSIG_SECRET    = var.dns_secret
    }
  }
}
```

```hcl [providers.tf]
terraform { // [!code focus:16]
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    acme = { // [!code --:3]
      source = "vancluever/acme"
    }
    tls = {
      source = "hashicorp/tls"
    }
    dns = {
      source = "hashicorp/dns"
    }
  }
  required_version = ">= 0.13"
}

# ... Other non-relevant providers for this exercise ...

provider "acme" { // [!code focus:3] [!code --:3]
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
```

```yml [tpl/userData.yml]
#cloud-config
users:
  - name: ${login_user}
    groups: [sudo]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${public_key_robin}

ssh_keys:
  ed25519_private: |
    ${tls_private_key}
ssh_pwauth: false
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages: // [!code ++:21]
  - caddy

write_files:
  - path: /etc/caddy/Caddyfile
    content: |
      {
          acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
      }

      ${server_names_string} {
          root * /var/www/html
          file_server
      }

runcmd:
  - mkdir -p /var/www/html
  - - >
  - echo "I'm Caddy @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
  - created $(date -u)" >> /var/www/html/index.html
  - systemctl enable caddy
  - systemctl restart caddy
```

:::

This configuration creates a server with Caddy installed and configured to serve HTTPS traffic for the specified domain and subdomains. The certificate is directly created by Caddy using Let's Encrypt's HTTP-01 challenge method, which is much simpler than DNS challenges as it doesn't require programmatic DNS updates or complex RFC2136 configuration. Since Caddy handles all certificate management internally, you no longer need the ACME provider in Terraform. Caddy automatically generates certificates, validates domain ownership, and renews them when needed.
