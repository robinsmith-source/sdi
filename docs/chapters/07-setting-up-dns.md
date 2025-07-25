# Setting up DNS

> This guide covers setting up and managing DNS records using the dedicated nameserver ns1.hdm-stuttgart.cloud, including zone transfers, record management, and security considerations.

## Prerequisites

Before you begin, ensure you have:

- Access to your group's DNS zone (e.g., g10.sdi.hdm-stuttgart.cloud)
- Your group's HMAC secret key (provided in your dnsupdate.sec file)
- Basic understanding of DNS concepts and tools (dig, nsupdate)
- A web server set up (e.g., Nginx like in [Server Initialization](04-server-initialization#_1-using-bash-init-scripts-for-server-initialization-exercise-11) or just simply use Caddy)

## External Resources

For more in-depth information about DNS management:

- [BIND9 Documentation](https://bind9.readthedocs.io/) - Official BIND9 documentation
- [DNS Update Protocol](https://datatracker.ietf.org/doc/html/rfc2136) - RFC 2136
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/) - SSL/TLS certificate management
- [Nginx Documentation](https://nginx.org/en/docs/) - Nginx web server configuration
- [Caddy Documentation](https://caddyserver.com/docs/) - Caddy web server configuration

## 1. Understanding Your DNS Zone

Each group is assigned a dedicated subdomain on the ns1.hdm-stuttgart.cloud nameserver. For example, Group 3's zone would be `g10.sdi.hdm-stuttgart.cloud`.

### Zone Transfer

To view your current DNS records, you can perform a zone transfer using the `dig` command with your HMAC key:

```bash
# Export your HMAC key as an environment variable
export HMAC=hmac-sha512:g10.key:gEVK/4vI9OK...

# Perform a full zone transfer to list all records in your DNS zone
dig @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g10.sdi.hdm-stuttgart.cloud
```

This will show all records in your zone, including:

- SOA (Start of Authority) record
- NS (Nameserver) record
- Any existing A, CNAME, or other records

## 2. Managing DNS Records

### Adding Records

To add a new A record (e.g., for a web server), use the `nsupdate` command:

```bash
# Start an nsupdate session with your HMAC key
nsupdate -y $HMAC

# Specify the DNS server to connect to
server ns1.hdm-stuttgart.cloud

# Add an A record for your web server (replace with your actual IP)
update add www.g10.sdi.hdm-stuttgart.cloud 10 A 141.62.75.114

# Send the update and exit the session
send
quit
```

# Check if the record was added successfully

```bash
dig +noall +answer @ns1.hdm-stuttgart.cloud www.g10.sdi.hdm-stuttgart.cloud
```

### Modifying Records

To modify a record, you must first delete it and then create the new version:

```bash
# Start an nsupdate session
nsupdate -y $HMAC
# Connect to the DNS server
server ns1.hdm-stuttgart.cloud
# Delete the old A record (replace with the correct IP if needed)
update delete www.g10.sdi.hdm-stuttgart.cloud. 10 IN A 141.62.75.114
send
quit
```

::: warning **TTL Considerations**

- Records have a Time To Live (TTL) value that determines how long they can be cached.
- Higher TTL values mean longer wait times for updates to propagate globally.
- Consider using lower TTL values during development and higher values in production.
  :::

## 3. Enhancing Your Web Server [Exercise 18]

### Task Description

In this exercise, you will:

1. Assign a DNS name to your web server (e.g., http://www.gXY.sdi.hdm-stuttgart.cloud)
2. Enable HTTPS by configuring TLS on your web server

### Step-by-Step Guide

1. **DNS Configuration**
   Add an A record for your web server using `nsupdate`. Replace `<YOUR_SERVER_IP>` with your actual server IP address:

   ```bash
   # Add an A record for your web server (replace <YOUR_SERVER_IP> with your actual server IP)
   nsupdate -y $HMAC
   server ns1.hdm-stuttgart.cloud
   update add www.g10.sdi.hdm-stuttgart.cloud 10 A <YOUR_SERVER_IP>
   send
   quit
   ```

2. **Web Server Setup**

Take the cloud-init configuration file from [Server Initialization](04-server-initialization#_1-using-bash-init-scripts-for-server-initialization-exercise-11) and modify it to include the following:

```yaml
#cloud-config
users:
  - name: ${loginUser}
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

packages:
  - caddy #[!code ++]
  - fail2ban
  - plocate
  - python3-systemd # Add python3-systemd for fail2ban backend

write_files:
  - path: /etc/fail2ban/jail.local # [!code ++:18]
    content: |
      [DEFAULT]
      # Ban hosts for 1 hour:
      bantime = 1h

      # Override /etc/fail2ban/jail.d/defaults-debian.conf:
      backend = systemd

      [sshd]
      enabled = true
      # To use internal sshd filter variants
  - path: /etc/caddy/Caddyfile
    content: |
      www.g10.sdi.hdm-stuttgart.cloud {
        root * /var/www/html
        file_server
      }

runcmd:
  # Caddy setup [!code ++:6]
  - systemctl enable caddy
  - mkdir -p /var/www/html
  - >
    echo "I'm Caddy @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  - systemctl enable fail2ban
  - systemctl start fail2ban
  - updatedb
  - systemctl restart fail2ban
  - systemctl start caddy
```

### Verification

After completing the steps above, verify your setup:

1. **Check DNS resolution:**
   Use a public DNS resolver to confirm your A record is active:

   ```bash
   dig +noall +answer @8.8.8.8 www.g10.sdi.hdm-stuttgart.cloud
   ```

2. **Verify HTTPS:**
   Ensure your web server is accessible via HTTPS:
   ```bash
   curl -I https://www.g10.sdi.hdm-stuttgart.cloud
   ```

## 4. Creating DNS Records with Terraform [Exercise 19]

Terraform can be used to manage DNS records in a declarative way. This allows you to define your DNS records in code and apply them automatically.

### Terraform Configuration

The following Terraform configuration creates an A record and a CNAME record:

```hcl
# A record for the server's canonical name (e.g., workhorse.g10.sdi.hdm-stuttgart.cloud)
resource "dns_a_record_set" "server_a" {
  zone      = "${var.dns_zone}."
  name      = var.server_name
  addresses = [var.server_ip]
  ttl       = 10
}

# CNAME records for server aliases using count meta-argument
resource "dns_cname_record" "server_aliases" {
  count      = length(var.server_aliases)
  zone       = "${var.dns_zone}."
  name       = var.server_aliases[count.index]
  cname      = "${var.server_name}.${var.dns_zone}."
  ttl        = 300
  depends_on = [dns_a_record_set.server_a]
}
```

## 5. Creating a Host with Corresponding DNS Entries [Exercise 20]

This exercise combines server creation and DNS record management into a single Terraform configuration.

### Terraform Configuration

The following configuration creates a server and its corresponding DNS records:

```hcl
resource "hcloud_server" "debian_server" {
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
  addresses = [hcloud_server.debian_server.ipv4_address]
  ttl       = 10
}
```

## 6. Creating a Fixed Number of Servers [Exercise 21]

Terraform's `count` meta-argument can be used to create a fixed number of resources. This is useful for creating multiple servers with similar configurations.

### Terraform Configuration

The following configuration creates two servers and their corresponding DNS records:

```hcl
resource "hcloud_server" "debian_server" {
  count        = 2
  name         = "debian-server-${count.index}"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "dns_a_record_set" "server_a" {
  count     = 2
  zone      = "${var.dns_zone}."
  name      = "server-${count.index}"
  addresses = [hcloud_server.debian_server[count.index].ipv4_address]
  ttl       = 10
}
```
