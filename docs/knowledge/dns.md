# DNS <Badge type="info" text="Networking" />

> The Domain Name System (DNS) is the backbone of the internet, translating human-friendly domain names into IP addresses that computers use to communicate.

::: info Purpose
DNS enables:
- Easy-to-remember names for internet resources
- Decoupling of service names from physical infrastructure
- Load balancing, redundancy, and service discovery
:::

## Core Concepts {#core-concepts}

### What is DNS?
DNS is a distributed, hierarchical system that maps domain names (like `example.com`) to IP addresses. It acts as the internet's phonebook, allowing users to access websites and services using names instead of numbers.

### How DNS Works
1. **User Request:** You enter a domain name in your browser.
2. **Recursive Resolver:** Your device queries a DNS resolver (often provided by your ISP).
3. **Root Servers:** If the resolver doesn't know the answer, it asks a root DNS server for the TLD (e.g., `.com`).
4. **TLD Servers:** The resolver asks the TLD server for the authoritative server for the domain.
5. **Authoritative Server:** The resolver queries the authoritative server, which returns the IP address.
6. **Response:** The resolver sends the IP address back to your device, which connects to the website.

### Record Types
- **A:** Maps a domain to an IPv4 address
- **AAAA:** Maps a domain to an IPv6 address
- **CNAME:** Points one domain to another domain (alias)
- **MX:** Specifies mail servers for a domain
- **TXT:** Stores arbitrary text (e.g., SPF, DKIM)
- **NS:** Indicates authoritative nameservers for the domain
- **SOA:** Start of Authority; contains zone information
- **PTR:** Used for reverse DNS (IP to name)
- **SRV:** Specifies services available in the domain

::: tip TTL & Propagation
- **TTL (Time To Live):** How long a DNS record is cached by resolvers and clients
- **Propagation:** DNS changes may take time to spread due to caching
:::

## Essential Commands <Badge type="tip" text="Core CLI" />

```sh
# Query A record for a domain
dig example.com A
# Query all records for a domain
dig example.com ANY
# Query a specific nameserver
dig @8.8.8.8 example.com
# Use nslookup (alternative)
nslookup example.com
# Use host (lightweight)
host example.com
```

```sh
# Windows: Flush DNS cache
ipconfig /flushdns
# Linux (systemd):
sudo systemd-resolve --flush-caches
# macOS:
dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

## Best Practices

- Use low TTL values when testing or making frequent changes; increase TTL in production for stability
- Double-check record syntax and values before applying changes
- Use multiple tools (dig, nslookup, host) to verify DNS records from different locations
- Document your DNS setup and changes for future reference

## Common Use Cases

- **Website Hosting:**
  - Point your domain's A/AAAA record to your web server's IP address
  - Use CNAME records for subdomains (e.g., `www` → root domain)
- **Email Delivery:**
  - Set MX records to specify mail servers
  - Add TXT records for SPF, DKIM, and DMARC to improve email security
- **Service Discovery:**
  - Use SRV records for services like SIP, XMPP, or Microsoft services
- **Reverse DNS:**
  - Set PTR records to map IP addresses back to domain names (often required for mail servers)

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details DNS Not Resolving
- Check for typos in domain names and record values
- Ensure authoritative nameservers are set correctly
- Use `dig` or `nslookup` to query different DNS servers
- Check DNS propagation status with online tools (e.g., whatsmydns.net)
:::

::: details Email Delivery Issues
- Verify MX, SPF, DKIM, and DMARC records
- Use online tools to test email configuration (e.g., MXToolbox)
:::

::: details Stale Records / Propagation Delays
- Lower TTL before making changes if possible
- Flush local and resolver caches
- Be patient; global propagation can take up to 48 hours
:::

---

DNS is fundamental to the operation of the internet. Understanding its concepts, tools, and best practices is essential for anyone managing domains or infrastructure.
