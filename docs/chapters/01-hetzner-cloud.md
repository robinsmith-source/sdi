# Hetzner Cloud

> This guide explains how to set up a Hetzner Cloud server, enhance its security, and establish an SSH key-based connection.

## Prerequisites

Before you begin, ensure you have:

- A web browser
- Familiarity with command-line interfaces
- An SSH client:
  - macOS and Linux: Built-in OpenSSH client
  - Windows: Windows Terminal with OpenSSH or PuTTY

## External Resources

For more in-depth information about Hetzner Cloud and server security:

- [Hetzner Cloud Documentation](https://docs.hetzner.com/cloud/) - Official Hetzner Cloud documentation
- [Arch Wiki: Firewalls](https://wiki.archlinux.org/title/Firewalls) - Firewall configuration guide
- [Arch Wiki: Security](https://wiki.archlinux.org/title/Security) - General security best practices
- [Arch Wiki: SSH Keys](https://wiki.archlinux.org/title/SSH_keys) - SSH key management
- [Arch Wiki: Systemd](https://wiki.archlinux.org/title/Systemd) - Systemd service management

## 1. Creating a Hetzner Account

1. Register at https://accounts.hetzner.com/signUp.
2. Complete the account verification process (ID verification may be requested).
3. For enhanced account security, enable two-factor authentication (2FA).

## 2. Creating Your First Server [Exercise 1]

1. Go to https://www.hetzner.com and click "Login" in the top-right corner.
2. From the dropdown menu, select "Cloud".
3. Choose your project or create a new one.
4. In the left-hand navigation panel, select `Server`, then click `Add Server`.
5. Configure your server with the following settings:
   - **Location**: Choose Helsinki or Frankfurt.
   - **Image**: Select Debian 12.
   - **Type**: Opt for Shared vCPU / x86 (Intel/AMD). CXC22 or CPX11 are good starting points, depending on availability and your needs.
   - **Name**: Assign a descriptive name to your server.
6. Click "Create & Buy Now".

## 3. Accessing Your Server (Initial Method)

1. In your server list, click on your newly created server.
2. Navigate to the "Rescue" tab.
3. Click "Reset Root Password" and carefully copy the generated password.
4. Open the web-based console by clicking the `>_` icon in the upper-right corner of the server details page.
5. Log in using:
   - Username: `root`
   - Password: (paste the password you copied)

## 4. Key Security Vulnerabilities of the Initial Setup

Be aware that the default server configuration has several security weaknesses:

- **Password-based authentication**: This is susceptible to brute-force attacks.
- **No automatic updates**: Software can become outdated and vulnerable over time.
- **No firewall**: All server ports are potentially exposed to the internet.
- **Unrestricted service access**: Services like databases may be accessible without limitation.

## 5. Creating SSH Keys for Secure Authentication [Exercise 2]

1. Open a terminal window on your local computer.
2. Generate a new SSH key pair:
   ```sh
   ssh-keygen -t ed25519
   ```
3. When prompted for the file location, press Enter to accept the default (usually `~/.ssh/id_ed25519`).
4. For optimal key security, set a strong passphrase when prompted.
5. Verify that your `~/.ssh` directory now contains:
   - Private key: `id_ed25519`
   - Public key: `id_ed25519.pub`
   - `known_hosts` file. If `known_hosts` is missing, create it with:
     ```sh
     touch ~/.ssh/known_hosts
     ```

## 6. Improving Server Security [Exercise 3]

1. In the Hetzner Cloud Console, navigate to `Firewalls`. Create a new firewall with these rules:
   - Rule 1: Allow TCP traffic on Port `22` (for SSH access).
   - Rule 2: Allow ICMP traffic (for ping functionality).
2. Next, go to the `Security` tab in the Cloud Console to add your public SSH key:
   - Copy the entire contents of your public key file (`~/.ssh/id_ed25519.pub`).
   - Paste the copied public key into the designated field and assign it a descriptive name (e.g., "My Laptop Key").
3. To avoid unnecessary charges, delete the server you created initially (which used password authentication).
4. Create a new server. During this setup process, ensure you select the firewall you just configured and your newly added SSH key.

## 7. Testing Server Connectivity

1. From your server's details page in the Hetzner Cloud Console, copy its IP address.
2. Verify network connectivity to your server:
   ```sh
   ping YOUR_SERVER_IP
   ```
   Successful pings indicate your server is reachable on the network.
