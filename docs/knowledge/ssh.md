# SSH

> SSH is a secure protocol for remote access and file transfer. It uses public-key cryptography to authenticate and encrypt connections, providing a secure and efficient way to manage remote servers.

## Core Concepts {#core-concepts}

SSH uses public-key cryptography to authenticate and encrypt connections, providing secure remote access and file transfer capabilities.

### Key Concepts Explained

::: details Key Pairs
SSH key pairs consist of a public key (shared) and a private key (kept secret). The public key is placed on remote servers, while the private key remains on your local machine for authentication.
:::

::: details SSH Agent
A background program that manages your SSH keys and passphrases. It stores decrypted private keys in memory, eliminating the need to enter passphrases repeatedly during a session.
:::

::: details SSH Config
A configuration file (`~/.ssh/config`) that simplifies connection management by storing connection parameters for different hosts, reducing the need to remember complex command-line options.
:::


## Essential Commands <Badge type="tip" text="Core CLI" />

### Key Generation

```sh
# Generate a new Ed25519 key
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Verifying Your Keys

```sh
# List your keys
ls ~/.ssh/id_ed25519*
```

### Using SSH Keys

```sh
# Add your key to the agent
ssh-add ~/.ssh/id_ed25519
```

### SSH Config File

```sh
# Example ~/.ssh/config
Host myserver
  HostName 192.168.1.100
  User myuser
  Port 2222
  IdentityFile ~/.ssh/server_key

Host github.com
  User git
  IdentityFile ~/.ssh/github_key
  IdentitiesOnly yes

Host internal-db
  HostName 10.0.5.10
  ProxyJump myserver
```

### File Transfer

```sh
# Copy local file TO remote
scp local_file.txt user@remotehost:/remote/path/
# Copy remote file TO local
scp user@remotehost:/remote/path/file.txt ./local/path/
# Copy directory recursively
scp -r local_directory user@remotehost:/remote/path/
# Start an SFTP session
sftp user@remotehost
```

## Best Practices

- Use Ed25519 keys for modern security
- Protect your private key with a strong passphrase
- Set correct permissions on key files (`chmod 600` for private, `644` for public)
- Use SSH agent for convenience and security
- Use SSH config to simplify connections
- Never share your private key

## Common Use Cases

- **Remote server management** (login, command execution)
- **Git operations** (GitHub, GitLab, etc.)
- **Automated deployments** (CI/CD, Ansible, etc.)
- **Secure file transfers** (SCP, SFTP)
- **Tunneling and port forwarding**

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details Permission denied (publickey)

- Check if your public key is added to remote's `~/.ssh/authorized_keys`
- Verify permissions: `~/.ssh` (700), `authorized_keys` (600), private key (600)
- Ensure SSH agent has your key loaded: `ssh-add -l`
- Try connecting with verbose output: `ssh -vv user@host`
  :::

::: details Connection timed out / refused

- Is the server running and reachable?
- Check firewalls and security groups
- Verify the SSH port is correct and open
- Test basic connectivity: `ping hostname`
  :::
