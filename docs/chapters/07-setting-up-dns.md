# Setting up DNS

> This guide covers setting up and managing DNS records using the dedicated nameserver ns1.hdm-stuttgart.cloud, including zone transfers, record management, and security considerations.

## Prerequisites

Before you begin, ensure you have:

- Access to your group's DNS zone (e.g., g3.sdi.hdm-stuttgart.cloud)
- Your group's HMAC secret key (dnsupdate.sec file)
- Basic understanding of DNS concepts and tools (dig, nsupdate)

## External Resources

For more in-depth information about DNS management:

- [BIND9 Documentation](https://bind9.readthedocs.io/) - Official BIND9 documentation
- [DNS Update Protocol](https://datatracker.ietf.org/doc/html/rfc2136) - RFC 2136
- [TSIG Documentation](https://bind9.readthedocs.io/en/latest/reference.html#tsig) - TSIG key management
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/) - SSL/TLS certificate management
- [Nginx Documentation](https://nginx.org/en/docs/) - Nginx web server configuration
- [Caddy Documentation](https://caddyserver.com/docs/) - Caddy web server configuration

## 1. Understanding Your DNS Zone

Each group is assigned a dedicated subdomain on the ns1.hdm-stuttgart.cloud nameserver. For example, Group 3's zone would be `g3.sdi.hdm-stuttgart.cloud`.

### Zone Transfer

To view your current DNS records, you can perform a zone transfer using the `dig` command with your HMAC key:

```bash
# Set your HMAC key as an environment variable
export HMAC=hmac-sha512:g3.key:I5sDDS3L1BU...

# Perform zone transfer
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
# Start nsupdate session
nsupdate -y $HMAC

# Connect to the nameserver
server ns1.hdm-stuttgart.cloud

# Add an A record
update add www.g10.sdi.hdm-stuttgart.cloud 10 A 141.62.75.114

# Send the update and quit
send
quit
```

Verify the record was added:
```bash
dig +noall +answer @ns1.hdm-stuttgart.cloud www.g10.sdi.hdm-stuttgart.cloud
```

### Modifying Records

To modify a record, you must first delete it and then create the new version:

```bash
nsupdate -y $HMAC
server ns1.hdm-stuttgart.cloud
update delete www.g10.sdi.hdm-stuttgart.cloud. 10 IN A 141.62.75.114
send
quit
```

::: warning **TTL Considerations**
- Records have a Time To Live (TTL) value that determines how long they can be cached
- Higher TTL values mean longer wait times for updates to propagate globally
- Consider using lower TTL values during development and higher values in production
:::

## 3. Exercise: Enhancing Your Web Server

### Task Description

Enhance your web server by:
1. Setting up a proper DNS name (e.g., http://www.gXY.sdi.hdm-stuttgart.cloud)
2. Configuring TLS for HTTPS support

### Step-by-Step Guide

1. **DNS Configuration**
   ```bash
   # Add A record for your web server
   nsupdate -y $HMAC
   server ns1.hdm-stuttgart.cloud
   update add www.g10.sdi.hdm-stuttgart.cloud 10 A <YOUR_SERVER_IP>
   send
   quit
   ```

2. **Web Server Setup**

Take the cloud-init configuration file from [Server Initialization](04-server-initialization) and modify it to include the following:
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
  - caddy # [!code ++]
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
  # Caddy setup [!code ++:5]
  - systemctl enable caddy
  - mkdir -p /var/www/html
  - >
    echo "I'm Caddy @ $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    created $(date -u)" >> /var/www/html/index.html
  - systemctl enable fail2ban
  - systemctl start fail2ban
  - updatedb
  - systemctl restart fail2ban
  - systemctl start caddy # [!code ++]
```

### Verification

1. Check DNS resolution:
   ```bash
   dig +noall +answer @8.8.8.8 www.g3.sdi.hdm-stuttgart.cloud
   ```

2. Verify HTTPS:
   ```bash
   curl -I https://www.g3.sdi.hdm-stuttgart.cloud
   ```
