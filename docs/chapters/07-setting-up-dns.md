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
dig @ns1.hdm-stuttgart.cloud -y $HMAC -t AXFR g3.sdi.hdm-stuttgart.cloud
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
update add www.g3.sdi.hdm-stuttgart.cloud 10 A 141.62.75.114

# Send the update and quit
send
quit
```

Verify the record was added:
```bash
dig +noall +answer @ns1.hdm-stuttgart.cloud www.g3.sdi.hdm-stuttgart.cloud
```

### Modifying Records

To modify a record, you must first delete it and then create the new version:

```bash
nsupdate -y $HMAC
server ns1.hdm-stuttgart.cloud
update delete www.g3.sdi.hdm-stuttgart.cloud. 10 IN A 141.62.75.114
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
   update add www.g3.sdi.hdm-stuttgart.cloud 10 A YOUR_SERVER_IP
   send
   quit
   ```

2. **Web Server Setup**

   You can choose between Nginx or Caddy as your web server. Both are excellent choices, with Caddy offering automatic HTTPS by default.

   #### Option A: Using Nginx

   ```bash
   # Install Nginx
   apt update
   apt install nginx

   # Create a basic site configuration
   cat > /etc/nginx/sites-available/g3.sdi.hdm-stuttgart.cloud << 'EOF'
   server {
       listen 80;
       server_name www.g3.sdi.hdm-stuttgart.cloud;
       root /var/www/html;
       index index.html;

       location / {
           try_files $uri $uri/ =404;
       }
   }
   EOF

   # Enable the site
   ln -s /etc/nginx/sites-available/g3.sdi.hdm-stuttgart.cloud /etc/nginx/sites-enabled/
   nginx -t
   systemctl restart nginx
   ```

   **TLS Setup with Nginx:**
   ```bash
   # Install Certbot
   apt install certbot python3-certbot-nginx

   # Test certificate generation using staging
   certbot --staging -d www.g3.sdi.hdm-stuttgart.cloud --nginx

   # Generate production certificate
   certbot -d www.g3.sdi.hdm-stuttgart.cloud --nginx
   ```

   The Certbot will automatically modify your Nginx configuration to include HTTPS settings.

   #### Option B: Using Caddy

   Caddy is a modern web server with automatic HTTPS support built-in.

   ```bash
   # Install Caddy
   apt install -y debian-keyring debian-archive-keyring apt-transport-https
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
   apt update
   apt install caddy

   # Create Caddyfile
   cat > /etc/caddy/Caddyfile << 'EOF'
   www.g3.sdi.hdm-stuttgart.cloud {
       root * /var/www/html
       file_server
       encode gzip
   }
   EOF

   # Start Caddy
   systemctl restart caddy
   ```

   Caddy will automatically:
   - Obtain SSL certificates from Let's Encrypt
   - Configure HTTPS
   - Handle certificate renewals
   - Redirect HTTP to HTTPS

### Verification

1. Check DNS resolution:
   ```bash
   dig +noall +answer @8.8.8.8 www.g3.sdi.hdm-stuttgart.cloud
   ```

2. Verify HTTPS:
   ```bash
   curl -I https://www.g3.sdi.hdm-stuttgart.cloud
   ```
