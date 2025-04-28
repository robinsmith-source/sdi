# Hetzner Cloud: Creating and Securing Your First Server

## Prerequisites

- Basic knowledge of command-line interfaces
- A web browser
- SSH client (built into macOS/Linux, Windows users can use Windows Terminal or PuTTY)

## 1. Creating a Hetzner Account

1. Sign up at https://accounts.hetzner.com/signUp
2. Complete account verification (ID verification may be required)
3. Consider enabling two-factor authentication for added security

## 2. Creating Your First Server

1. Navigate to https://www.hetzner.com and click on "Login" in the top-right corner
2. Select "Cloud" from the dropdown menu
3. Choose your project
4. In the left navigation, select `Server` and click `Add Server`
5. Configure your server with:
   - **Location**: Helsinki or Frankfurt
   - **Image**: Debian 12
   - **Type**: Shared vCPU / x86 (Intel/AMD) / CXC22 or CPX11 depending on availability
   - **Name**: Choose a name for your server
6. Click "Create & Buy Now"

## 3. Accessing Your Server (Initial Method)

1. Click on your new server in the list
2. Go to the "Rescue" tab
3. Click "Reset Root Password" and copy the generated password
4. Open the console by clicking the `>_` symbol in the upper right
5. Log in with:
   - Username: `root`
   - Password: _paste the generated password_

## 4. Security Considerations

Your initial server setup has several security vulnerabilities:

- Password-based authentication (vulnerable to brute force attacks)
- No automatic updates (potentially outdated software)
- No firewall (all ports potentially exposed)
- No restricted access to services (databases, etc.)

## 5. Creating SSH Keys for Secure Authentication

1. Open a terminal on your local machine
2. Generate an SSH key pair:
   ```bash
   ssh-keygen -t ed25519
   ```
3. When prompted, press Enter to use the default file location (usually `~/.ssh/id_ed25519`)
4. It's strongly recommended to set a secure passphrase for additional security
5. Ensure your `.ssh` directory contains:
   - Private key (`id_ed25519`)
   - Public key (`id_ed25519.pub`)
   - Known hosts file (`known_hosts`) - create if it doesn't exist:
     ```bash
     touch ~/.ssh/known_hosts
     ```

## 6. Improving Server Security

1. Go to `Firewalls` in the left navigation and create a new firewall with:
   - Rule 1: TCP, Port 22 (SSH access)
   - Rule 2: ICMP (ping functionality)
2. Go to the `Security` tab and add your SSH key:
   - Copy the contents of your `id_ed25519.pub` file
   - Paste it into the SSH key field and give it a name
3. Delete your current server to avoid charges
4. Create a new server, selecting your firewall and SSH key during setup

## 7. Testing Server Connectivity

1. Copy your server's IP address from the server details page
2. Test if your server is reachable:
   ```bash
   ping YOUR_SERVER_IP
   ```
   You should see successful ping responses
