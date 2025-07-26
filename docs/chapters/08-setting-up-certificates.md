# Setting up Certificates

> This guide covers SSL/TLS certificate management with Terraform and the ACME provider, including automated certificate generation, DNS challenges, and web server deployment with proper certificate configuration.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account and API token
- Terraform installed on your local machine
- Access to your group's DNS zone (e.g., g03.sdi.hdm-stuttgart.cloud)
- Your group's HMAC secret key for DNS updates
- Basic understanding of SSL/TLS certificates and DNS
- A web server setup (Nginx or similar)

## External Resources

For more in-depth information about SSL/TLS certificates and ACME:

- [Understanding Web Certificates](https://www.youtube.com/watch?v=T4Df5_cojAs) - Video presentation on web certificates
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/) - Official Let's Encrypt documentation
- [ACME Terraform Provider](https://registry.terraform.io/providers/vancluever/acme/latest/docs) - Official ACME provider documentation
- [RFC 2136 DNS Update](https://datatracker.ietf.org/doc/html/rfc2136) - DNS Update Protocol specification
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html) - Nginx HTTPS configuration guide

## Knowledge

For comprehensive information about certificate concepts, types, and security considerations, see [Certificates](/knowledge/certificates).

## 1. Certificates with Terraform

Terraform provides excellent support for certificate management through the ACME provider. The basic configuration includes:

```hcl
provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"

  # Production:
  # server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "nobody@example.com"
}

resource "acme_certificate" "certificate" {
  # ... certificate configuration
  dns_challenge {
    # ... DNS challenge configuration
  }
}
```

::: warning **Rate Limits**
Always use the staging URL `https://acme-staging-v02.api.letsencrypt.org/directory` during development and testing. Let's Encrypt has strict rate limits for the production endpoint!
:::

### DNS Challenge Providers

The ACME provider supports various DNS challenge providers for domain validation:

```hcl
resource "acme_certificate" "certificate" {
  # ... other configuration
  dns_challenge {
    provider = "route53"
    # ... provider-specific configuration
  }
}
```

Available DNS providers include:

- acme-dns
- alidns
- route53
- rfc2136
- zonomi
- And many more...

## 2. RFC2136 Provider Configuration

For DNS servers supporting RFC2136 dynamic updates (like the course nameserver), use the following configuration:

```hcl
dns_challenge {
  provider = "rfc2136"

  config = {
    RFC2136_NAMESERVER     = "ns1.sdi.hdm-stuttgart.cloud"
    RFC2136_TSIG_ALGORITHM = "hmac-sha512"
    RFC2136_TSIG_KEY       = "g10.key."
    RFC2136_TSIG_SECRET    = var.dns_secret # Relates to environment variable TF_VAR_dns_secret
  }
}
```

### BIND Server Logs

When ACME challenges are processed, you'll see entries like this in your BIND server logs:

```
... updating zone 'goik.sdi.hdm-stuttgart.cloud/IN':
  deleting rrset at '_acme-challenge.goik.sdi.hdm-stuttgart.cloud' TXT
... updating zone 'goik.sdi.hdm-stuttgart.cloud/IN':
    adding an RR at '_acme-challenge.goik.sdi.hdm-stuttgart.cloud' TXT
      "GtJZJZjCZLWoGsQDODCFnY37TmMjRiy8Hw9M1eDGhkQ"
... deleting rrset at ... TXT
... adding an RR ... TXT "eJckWl2F43nsf27bzVOjcrTGp_VFeCj2qTVM5Uodg-4"
... deleting an RR at _acme-challenge.goik.sdi.hdm-stuttgart.cloud TXT
... updating zone ... deleting an RR ... TXT
```

## 3. Creating a Web Certificate [Exercise 22]

### Task Description

Create a wildcard certificate using Terraform and the ACME provider for your group's domain.

::: warning **Provider Version Requirements**
Due to a DNS provider related issue, you must use at least acme provider version v2.23.2. You are best off not specifying any version at all to receive the latest release automatically.
:::

### Terraform Configuration

Set up your Terraform providers:

```hcl
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    acme = {
      source = "vancluever/acme"
    }
  }
  required_version = ">= 0.13"
}
```

### Certificate Generation

Assuming your group has write privileges to a zone `g03.sdi.hdm-stuttgart.cloud`, create a wildcard certificate for:

- The zone apex: `g03.sdi.hdm-stuttgart.cloud`
- `www.g03.sdi.hdm-stuttgart.cloud`
- `mail.g03.sdi.hdm-stuttgart.cloud`

Use the `subject_alternative_names` attribute for multiple domains.

The web server certificate installation requires two files:

- Private key file (e.g., `private.pem`)
- Certificate key file (e.g., `certificate.pem`)

Use `resource "local_file"` to generate this key pair in a `gen` subfolder of your current project.

## 4. Testing Your Web Certificate [Exercise 23]

### Task Description

Deploy and test the certificate on a web server with multiple DNS entries.

### Server Configuration

Create a host with three corresponding DNS entries:

- `g03.sdi.hdm-stuttgart.cloud`
- `www.g03.sdi.hdm-stuttgart.cloud`
- `mail.g03.sdi.hdm-stuttgart.cloud`

Your Terraform setup should contain a `config.auto.tfvars` file allowing for an arbitrary number of DNS names:

```hcl
# ...
dnsZone     = "g03.sdi.hdm-stuttgart.cloud"
serverNames = ["www", "cloud"]
# ...
```

### Web Server Setup

1. Install the Nginx web server
2. Modify the Nginx configuration to accept HTTPS requests using the generated certificate

::: tip **Nginx SSL Configuration**
The Nginx default configuration already contains a self-signed certificate referenced by `/etc/nginx/snippets/snakeoil.conf`. In `/etc/nginx/sites-available/default`, all SSL supporting statements are commented out:

```nginx
# SSL configuration
#
# listen 443 ssl default_server;
# listen [::]:443 ssl default_server;
# ...
# Self signed certs generated by the ssl-cert package
# Don't use them in a production server!
#
# include snippets/snakeoil.conf;
```

:::

### Testing and Verification

After modifying the configuration, check for correctness:

```bash
root@www:~# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Correct any misconfiguration issues before restarting Nginx:

```bash
systemctl restart nginx
```

**Verification Steps:**

1. Your staging certificate will cause warnings initially
2. Point your browser to all three URLs and overrule certificate warnings
3. Inspect the certificate - you should find `g03.sdi.hdm-stuttgart.cloud` and `*.g03.sdi.hdm-stuttgart.cloud`
4. If the certificate is working correctly, regenerate it using the production setting `https://acme-v02.api.letsencrypt.org/directory`
5. Don't forget to revert back to staging after completion!

## 5. Combining Certificate Generation and Server Creation [Exercise 24]

### Task Description

Create a unified Terraform configuration that combines certificate generation and server deployment into a single, cohesive infrastructure-as-code solution.

### Implementation Goals

Combine the configurations from the previous exercises into one comprehensive Terraform setup that:

1. **Generates the SSL certificate** using the ACME provider
2. **Creates the server infrastructure** on Hetzner Cloud
3. **Configures DNS records** for all required subdomains
4. **Deploys and configures the web server** with the certificate

This unified approach ensures that your entire infrastructure, including certificates, is managed as code and can be deployed consistently across environments. The configuration should be idempotent and handle certificate renewals automatically.
