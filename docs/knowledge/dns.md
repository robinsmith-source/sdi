# DNS

> The Domain Name System (DNS) translates human-friendly website names (like `google.com`) into numerical IP addresses (like `172.217.160.142`) that computers use to find each other. It's the internet's phonebook, making it possible to reach websites by name.

## Core Concepts {#core-concepts}

DNS is a distributed system that maps domain names to IP addresses, allowing access to online services using names instead of numbers. It's a hierarchical, decentralized naming system that forms the backbone of internet navigation.

### Key Concepts Explained

::: details DNS Resolution Process

1. **Request**: You enter a domain name in your browser
2. **Resolver Query**: Your computer asks a DNS resolver (e.g., from your ISP)
3. **Server Search**: The resolver queries root, TLD, and authoritative DNS servers
4. **Connection**: The IP address is returned and your computer connects to the website
   :::

::: details Common DNS Record Types

- **A Record**: Maps a domain to an IPv4 address
- **AAAA Record**: Maps a domain to an IPv6 address
- **CNAME Record**: Points one domain to another (an alias)
- **MX Record**: Specifies mail servers for a domain
- **TXT Record**: Stores arbitrary text (e.g., for email security like SPF, DKIM)
- **NS Record**: Indicates authoritative nameservers for the domain
- **SOA Record**: Contains administrative information about a DNS zone
- **PTR Record**: Used for reverse DNS (IP to name translation)
- **SRV Record**: Specifies the location of specific services
  :::

::: details DNS Concepts

- **TTL (Time To Live)**: How long DNS records are cached by resolvers
- **Propagation**: Time for DNS changes to update worldwide (minutes to 48 hours)
- **Zone**: A portion of the DNS namespace managed by a specific organization
- **Nameserver**: A server that contains DNS records for a domain
  :::

## Essential Commands <Badge type="tip" text="Core CLI" />

### DNS Query Commands

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

# Query with specific record type
dig example.com MX
dig example.com TXT
dig example.com NS
```

### DNS Cache Management

```sh
# Flush local DNS cache (if changes aren't appearing)
# Windows:
ipconfig /flushdns

# Linux (systemd):
sudo systemd-resolve --flush-caches

# macOS:
dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# Check DNS cache on Linux
systemd-resolve --statistics
```

### Advanced DNS Tools

```sh
# Trace DNS resolution path
dig +trace example.com

# Show detailed DNS information
dig +short example.com
dig +noall +answer example.com

# Check DNS propagation
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com
dig @208.67.222.222 example.com

# Reverse DNS lookup
dig -x 8.8.8.8
```

## Best Practices

### DNS Configuration

- Use low TTL for testing, higher for production
- Double-check record syntax and values
- Verify DNS records with multiple tools and online services
- Document your DNS setup and changes
- Use appropriate record types for their intended purpose

### Security and Performance

- Implement DNSSEC for security
- Use multiple nameservers for redundancy
- Monitor DNS propagation and performance
- Set up DNS monitoring and alerting
- Use CDN services for improved performance

### Email Configuration

- Configure proper MX records for email delivery
- Set up SPF, DKIM, and DMARC records
- Use dedicated subdomains for email services
- Monitor email deliverability

## Common Use Cases

- **Website Hosting**: Point A/AAAA records to web server IPs; use CNAME for subdomains
- **Email Delivery**: Set MX records; add TXT records for SPF, DKIM, DMARC
- **Service Discovery**: Use SRV records for specific services
- **Reverse DNS**: Set PTR records (often for mail servers)
- **Load Balancing**: Use multiple A records for round-robin DNS
- **Geographic Routing**: Use different A records based on location

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details DNS Not Resolving
Check typos, authoritative nameservers, query different DNS servers, and check propagation status. Verify domain registration and nameserver configuration.
:::

::: details Email Delivery Issues
Verify MX, SPF, DKIM, and DMARC records. Use online email configuration testers to validate setup.
:::

::: details Stale Records / Propagation Delays
Lower TTL before changes, flush caches, and be patient. DNS changes can take up to 48 hours to propagate globally.
:::

::: details CNAME Conflicts
Ensure CNAME records don't conflict with other record types. CNAME records cannot coexist with other record types for the same name.
:::

::: details Nameserver Issues
Verify nameserver configuration and delegation. Check if nameservers are responding and properly configured.
:::
