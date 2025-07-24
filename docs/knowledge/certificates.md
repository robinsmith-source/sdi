# Certificates

## Understanding Web Certificates

Web certificates are essential for securing communications between web browsers and servers. They enable HTTPS connections and ensure data integrity and confidentiality. SSL/TLS certificates work by establishing an encrypted connection between a client (browser) and server, preventing eavesdropping and tampering with transmitted data.

### How Certificates Work

1. **Public Key Infrastructure (PKI)**: Certificates are based on asymmetric cryptography using public and private key pairs
2. **Certificate Authority (CA)**: Trusted third parties that issue and validate certificates
3. **Chain of Trust**: Certificates are validated through a hierarchical chain back to trusted root CAs
4. **Digital Signatures**: CAs digitally sign certificates to prove authenticity

## Certificate Trust Levels

There are three main types of SSL/TLS certificates based on validation level:

### Domain Validated (DV)

- **Validation Process**: Fully automated process solely based on DNS/infrastructure challenges
- **What's Verified**: The certificate authority (CA) only verifies that you control the domain name
- **Use Cases**: Most common for automated certificate generation, personal websites, blogs
- **Trust Level**: Basic - shows padlock icon in browsers
- **Issuance Time**: Minutes to hours
- **Cost**: Often free (e.g., Let's Encrypt)

### Organization Validated (OV)

- **Validation Process**: Involves checking the organization in question
- **What's Verified**: The CA verifies both domain ownership and organizational information
- **Use Cases**: Business websites, internal applications
- **Trust Level**: Medium - shows organization name in certificate details
- **Issuance Time**: Days to weeks
- **Cost**: Moderate pricing

### Extended Validation (EV)

- **Validation Process**: Includes additional checks such as telephone-based verification
- **What's Verified**: Extensive verification of organization identity, legal existence, and operational status
- **Use Cases**: E-commerce sites, banking, high-security applications
- **Trust Level**: Highest - historically showed green address bar (deprecated in modern browsers)
- **Issuance Time**: Weeks
- **Cost**: Most expensive

## Certificate Types by Coverage

### Single Domain Certificates

- Protects one specific domain (e.g., `example.com`)
- Does not cover subdomains unless explicitly specified

### Multi-Domain Certificates (SAN)

- Subject Alternative Names (SAN) certificates
- Can protect multiple different domains in a single certificate
- Useful for organizations with multiple domains

### Wildcard Certificates

- Protects a domain and all its first-level subdomains
- Uses asterisk notation (e.g., `*.example.com`)
- Covers `www.example.com`, `mail.example.com`, `api.example.com`, etc.
- Does not cover second-level subdomains (e.g., `test.api.example.com`)

## Certificate Lifecycle

### Issuance

1. **Key Generation**: Create public/private key pair
2. **Certificate Signing Request (CSR)**: Request certificate from CA
3. **Domain Validation**: Prove control over the domain
4. **Certificate Issuance**: CA signs and issues the certificate

### Installation

1. **Certificate Deployment**: Install certificate on web server
2. **Configuration**: Configure web server to use HTTPS
3. **Testing**: Verify certificate is working correctly

### Renewal

1. **Monitoring**: Track certificate expiration dates
2. **Automated Renewal**: Use tools like ACME for automatic renewal
3. **Validation**: Re-verify domain ownership during renewal

### Revocation

- Certificates can be revoked if compromised
- Certificate Revocation Lists (CRL) and Online Certificate Status Protocol (OCSP)

## ACME Protocol

The Automated Certificate Management Environment (ACME) protocol automates certificate lifecycle management:

### Key Features

- **Automated Issuance**: No manual intervention required
- **Domain Validation**: Automated proof of domain control
- **Renewal Management**: Automatic certificate renewal before expiration
- **Standardized Protocol**: RFC 8555 standard

### Challenge Types

**HTTP-01 Challenge**

- Places a file at a specific URL on your web server
- Requires port 80 to be accessible
- Cannot be used for wildcard certificates

**DNS-01 Challenge**

- Creates a specific DNS TXT record
- Works with any port configuration
- Supports wildcard certificates
- Requires DNS API access or manual intervention

**TLS-ALPN-01 Challenge**

- Uses TLS extension for validation
- Requires port 443 to be accessible
- Not commonly used

## Security Considerations

### Certificate Storage

- **Private Keys**: Must be stored securely and never shared
- **File Permissions**: Restrict access to certificate files
- **Backup**: Secure backup of certificates and keys

### Certificate Validation

- **Hostname Verification**: Ensure certificate matches the requested hostname
- **Chain Validation**: Verify the complete certificate chain
- **Expiration Checking**: Monitor and renew certificates before expiration

### Best Practices

- Use strong key lengths (RSA 2048+ or ECDSA 256+)
- Regular certificate rotation
- Monitor certificate transparency logs
- Implement proper error handling for certificate issues

## Common Certificate Errors

### Browser Warnings

- **Self-signed certificates**: Not trusted by browsers
- **Expired certificates**: Past their validity period
- **Hostname mismatch**: Certificate doesn't match the domain
- **Incomplete chain**: Missing intermediate certificates

### Troubleshooting

1. **Check certificate validity**: Verify dates and hostname
2. **Validate certificate chain**: Ensure all intermediate certificates are present
3. **Test with SSL tools**: Use online SSL checkers
4. **Review server logs**: Check for certificate-related errors
