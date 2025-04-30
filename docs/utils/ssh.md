---
title: SSH - Secure Shell
description: A structured guide to SSH keys, configuration, and secure remote access
---

# SSH <Badge type="info" text="Security" />

Secure Shell (SSH) provides encrypted connections to remote systems, enabling secure administration, file transfers, and Git operations.

## Core Concepts

SSH uses public-key cryptography to authenticate and encrypt connections:

- **Key pairs** consist of a public key (shared) and a private key (kept secret)
- **SSH agent** manages your keys and passphrases
- **SSH config** simplifies connection management

## Key Generation <Badge type="tip" text="Essential" />

SSH keys are more secure than passwords for authentication.

::: info Recommended Algorithm
Use **Ed25519** for modern security and performance.
:::

### Creating Your Keys

```bash
# Generate a new Ed25519 key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Follow prompts:
# 1. File location (default: ~/.ssh/id_ed25519) - Press Enter
# 2. Passphrase (recommended!) - Enter a strong passphrase
```

### Verifying Your Keys

```bash
# List your keys
ls ~/.ssh/id_ed25519*

# Output:
# id_ed25519      (Private Key - KEEP SECRET!)
# id_ed25519.pub  (Public Key - Share this one)
```

::: warning Protect Your Private Key

- **Never share the private key file** (the one without `.pub`).
- Use a strong passphrase.
- Set proper permissions: `chmod 600 ~/.ssh/id_ed25519` (private key) and `chmod 644 ~/.ssh/id_ed25519.pub` (public key).
  :::

## Using SSH Keys

### With GitHub <Badge type="info" text="Common" />

1.  **Copy your public key:**

    ::: code-group

    ```bash [macOS]
    cat ~/.ssh/id_ed25519.pub | pbcopy
    ```

    ```powershell [Windows (Git Bash/WSL)]
    cat ~/.ssh/id_ed25519.pub | clip
    ```

    ```bash Linux
    cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard
    ```

    :::
    _Or open `~/.ssh/id_ed25519.pub` and copy its content_

2.  **Add to GitHub:**

    - Go to GitHub → Settings → SSH and GPG keys → New SSH key
    - Paste the copied public key
    - Give it a title (e.g., "Work Laptop")
    - Click "Add SSH key"

3.  **Verify connection:**

    ```bash
    ssh -T git@github.com
    # Expect: "Hi username! You've successfully authenticated..."
    ```

_(Similar steps apply for GitLab and other Git hosting services)_

### With SSH Agent <Badge type="tip" text="Convenience" />

The SSH agent stores your key's passphrase in memory, so you don't need to re-enter it.

::: code-group

```bash [Linux/macOS Setup]
# Start agent
eval "$(ssh-agent -s)"

# Add your key (you'll be prompted for passphrase)
ssh-add ~/.ssh/id_ed25519
```

```powershell [Windows Setup]
# Enable and start the service (run as Admin if needed)
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent

# Add your key
ssh-add ~/.ssh/id_ed25519
```

:::

#### Verify Loaded Keys

```bash
# List keys in the agent
ssh-add -l
```

::: details Agent Forwarding
Use `ssh -A user@host` to use your local keys on the remote server.
⚠️ Only use with trusted servers to prevent security risks.
:::

## Configuration

### SSH Config File <Badge type="tip" text="Efficiency" />

Create `~/.ssh/config` to simplify connections:

```bash
# Example ~/.ssh/config

# Server with custom port
Host myserver
  HostName 192.168.1.100
  User myuser
  Port 2222
  IdentityFile ~/.ssh/server_key

# GitHub settings
Host github.com
  User git
  IdentityFile ~/.ssh/github_key
  IdentitiesOnly yes

# Jump host example
Host internal-db
  HostName 10.0.5.10
  ProxyJump myserver
```

Connect with simple commands:

```bash
ssh myserver
ssh github.com
ssh internal-db
```

### Common Config Options

| Option         | Purpose                |
| -------------- | ---------------------- |
| `Host`         | Connection alias       |
| `HostName`     | Real IP/domain         |
| `User`         | Remote username        |
| `Port`         | SSH port (default: 22) |
| `IdentityFile` | Path to private key    |
| `ProxyJump`    | Jump/bastion host      |

## File Transfer

SSH enables secure file transfers through SCP and SFTP:

### SCP (Secure Copy)

```bash
# Copy local file TO remote
scp local_file.txt user@remotehost:/remote/path/

# Copy remote file TO local
scp user@remotehost:/remote/path/file.txt ./local/path/

# Copy directory recursively
scp -r local_directory user@remotehost:/remote/path/
```

### SFTP (Interactive File Transfer)

```bash
# Start an SFTP session
sftp user@remotehost

# Common SFTP commands:
# ls, cd, pwd      - Remote filesystem navigation
# lls, lcd, lpwd   - Local filesystem navigation
# get remote_file  - Download a file
# put local_file   - Upload a file
# help             - Show all commands
# exit             - Close the session
```

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

## Security Best Practices

- Use strong, unique passphrases for each key
- Prefer Ed25519 keys over older algorithms
- Disable password authentication on servers where possible
- Regularly audit and rotate SSH keys
- Use separate keys for different services/purposes
