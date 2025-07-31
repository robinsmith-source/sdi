# Certificates

> SSL/TLS certificates are digital documents that secure online communication (HTTPS). They verify website identity, encrypt data, and build user trust by preventing eavesdropping and tampering.

## Core Concepts {#core-concepts}

SSL/TLS certificates use public-key cryptography to secure connections between clients and servers, ensuring data privacy and authenticity. They act as digital passports that verify website identity and encrypt data in transit.

### Key Concepts Explained

::: details Certificate Authority (CA)
Trusted organizations that issue and validate certificates. They digitally sign certificates to confirm authenticity and maintain the chain of trust.
:::

::: details Key Pairs
Each certificate involves a public key (shared) and a private key (kept secret). The private key must remain secure and never be shared.
:::

::: details Chain of Trust
Certificates are validated through a chain leading back to a trusted root CA. This hierarchical system ensures certificate authenticity.
:::

::: details Certificate Types

- **Domain Validated (DV)**: Basic validation confirming domain ownership (e.g., Let's Encrypt)
- **Organization Validated (OV)**: Verifies domain ownership and organizational details
- **Extended Validation (EV)**: Most rigorous validation with extensive identity checks
  :::

::: details Certificate Coverage

- **Single Domain**: Protects one specific domain (e.g., `example.com`)
- **Multi-Domain (SAN)**: Protects multiple distinct domains with one certificate
- **Wildcard**: Protects a domain and all its first-level subdomains (e.g., `*.example.com`)
  :::

## Essential Commands <Badge type="tip" text="Core CLI" />

### Certificate Generation and Inspection

```sh
# Generate a new private key and Certificate Signing Request (CSR)
openssl req -newkey rsa:2048 -nodes -keyout your_domain.key -out your_domain.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=your_domain.com"

# View the contents of a CSR
openssl req -in your_domain.csr -noout -text

# View the contents of a certificate
openssl x509 -in your_certificate.crt -noout -text

# Check certificate expiration date
openssl x509 -in your_certificate.crt -noout -enddate

# Verify a certificate chain
openssl verify -CAfile your_intermediate.crt your_certificate.crt

# Check a website's SSL certificate
openssl s_client -connect example.com:443 -servername example.com < /dev/null | openssl x509 -noout -text
```

### Modern Certificate Tools

```sh
# Caddy - Automatic HTTPS
caddy run --config Caddyfile

# Certbot - Let's Encrypt
sudo certbot --nginx -d your_domain.com -d www.your_domain.com

# Check certificate transparency
curl -s "https://crt.sh/?q=%.example.com&output=json" | jq

# Test SSL configuration
curl -I https://example.com
```

## Best Practices

### Security

- Keep private keys secure and never share them
- Restrict access to certificate files with proper permissions (600)
- Use strong key lengths (RSA 2048+ or ECDSA)
- Implement automatic renewal for certificates
- Monitor certificate expiration and transparency logs

### Configuration

- Validate certificate chains and hostname matching
- Use HSTS headers for additional security
- Configure proper SSL/TLS protocols and ciphers
- Set up monitoring and alerting for certificate expiration
- Use certificate transparency monitoring

## Common Use Cases

- **Website Security**: Enable HTTPS for web applications
- **API Protection**: Secure API endpoints with TLS
- **Email Security**: Use certificates for SMTP/TLS encryption
- **Internal Services**: Secure internal communication and services
- **Load Balancers**: Terminate SSL at load balancers
- **Microservices**: Secure inter-service communication

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details Browser Warnings
Often due to self-signed, expired, or mismatched certificates, or an incomplete certificate chain. Check certificate validity and ensure proper chain configuration.
:::

::: details Certificate Errors
Check validity, validate the chain, use SSL tools, and review server logs. Verify hostname matching and expiration dates.
:::

::: details Rate Limiting
Let's Encrypt has limits (300 certificates per domain per week, 5 duplicate certificates per week). Plan renewals accordingly.
:::

::: details DNS Issues
Ensure DNS records are properly configured and propagated. Verify domain ownership for certificate issuance.
:::
