# Hetzner Cloud

> This guide explains how to set up a Hetzner Cloud account and get access to your first server.

## Prerequisites

Before you begin, ensure you have:

- Familiarity with command-line interfaces
- An SSH client:
  - macOS and Linux: Built-in OpenSSH client
  - Windows: Windows Terminal with OpenSSH or PuTTY

## External Resources

For more in-depth information about Hetzner Cloud, firewalls, and SSH connections:

- [Hetzner Cloud: Create Server](https://docs.hetzner.com/cloud/servers/get-started/create-and-delete-server/) - Official guide for creating servers
- [Hetzner Cloud: Firewalls](https://docs.hetzner.com/cloud/servers/security/firewalls/) - Configuring firewalls in Hetzner Cloud
- [Hetzner Cloud: SSH Keys](https://docs.hetzner.com/cloud/servers/security/ssh-keys/) - Managing SSH keys in Hetzner Cloud
- [OpenSSH Manual](https://www.openssh.com/manual.html) - Official OpenSSH documentation

## 1. Creating a Hetzner Account

1. Register at https://accounts.hetzner.com/signUp.
2. Complete the account verification process (ID verification and payment method may be requested).
3. For enhanced account security, enable two-factor authentication (2FA).

## 2. Configuring a Firewall

Before we can create a server, we need to configure a firewall to allow SSH access.

1. Go to https://www.hetzner.com and click "Login" in the top-right corner.
2. From the dropdown menu, select "Cloud".
3. Choose your project or create a new one.
4. In the left-hand navigation panel, select `Firewalls`.
5. Click `Add Firewall`.
6. Configure the firewall with the following settings:
   - **Name**: Assign a descriptive name to your firewall.
   - **Rules**: Add a inbound rule to allow SSH access. 
   
   | IP Version | Protocol | Port |
   | ---------- | -------- | ---- |
   | Any IPv4 / Any IPv6 | TCP | 22 |

## 2. Creating Your First Server [Exercise 1] {#exercise-1}

This exercise guides you through creating your first Hetzner Cloud server and accessing it via SSH and the web GUI.

### 2.1 Server Creation

1. In the left-hand navigation panel, select `Server`, then click `Add Server`.
2. Configure your server with the following settings:
   - **Location**: Choose Helsinki or Frankfurt.
   - **Image**: Select Debian 12.
   - **Type**: Opt for Shared vCPU / x86 (Intel/AMD). CXC22 or CPX11 are good starting points, depending on availability and your needs.
   - **Name**: Assign a descriptive name to your server.
3. Click "Create & Buy Now".

### 2.2 Testing Server Connectivity

1. From your server's details page in the Hetzner Cloud Console, copy its IP address.
2. Verify network connectivity to your server:
   ```sh
   ping YOUR_SERVER_IP  
   ```
   Successful pings indicate your server is reachable on the network via ICMP.


### 2.3 Accessing Your Server via SSH

Once your server is created, you can access it via SSH using the root password provided by Hetzner via Email.

::: details You don't have access to the email?

You can also reset the password via the Hetzner Cloud Console.

1. In your server list, click on your newly created server
2. Navigate to the "Rescue" tab
3. Click "Reset Root Password" and carefully copy the generated password

:::

```sh
ssh root@YOUR_SERVER_IP
```

**Example:**
```sh
ssh root@95.216.187.60
```

### 2.4 Understanding the SSH Connection Message

When you connect for the first time, you'll see a message like this:

```
The authenticity of host '95.216.187.60 (95.216.187.60)' can't be established.
ED25519 key fingerprint is SHA256:vMMi2lkyhu0BPeqfncLzDRo6a1Ae8TtyVETebvh2ZwU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

::: details What does this message mean?

- **Host Authentication**: SSH is asking you to verify the server's identity
- **First Connection**: Since this is your first connection to this server, SSH doesn't have its host key stored
- **Security Check**: SSH is protecting you from potential man-in-the-middle attacks
- **Fingerprint**: The SHA256 hash is a unique identifier for the server's cryptographic key
- **Trust Decision**: You're being asked to trust this server and add its fingerprint to your `~/.ssh/known_hosts` file

**Response Options:**
- Type `yes` to accept and store the host key (recommended for your own server)
- Type `no` to reject the connection
- Type the fingerprint to verify it matches what you expect
:::


::: tip
**How SSH Keys Work**: SSH uses public-key cryptography for authentication. The server has a private key (kept secret) and a public key (shared with clients). When you connect, the server proves its identity by demonstrating it possesses the private key corresponding to the public key fingerprint shown.
:::

### 2.5 Accessing Your Server via Web GUI

You can also access your server through the Hetzner Cloud Console web interface:

1. In your server list, click on your newly created server
2. Open the web-based console by clicking the `>_` icon in the upper-right corner of the server details page
3. Log in using:
   - Username: `root`
   - Password: (paste the password you copied)

::: tip
**Keyboard Layout Issues**: If you experience key mapping problems (like switched y/z keys or non-digit keys not working), this is due to the US keyboard default configuration. You can fix this by running these commands in the web console after logging in:

```sh
dpkg-reconfigure keyboard-configuration
setupcon
```

Follow the interactive prompts to configure a DE keyboard layout.
:::

## 3. Key Security Vulnerabilities of the Initial Setup

Be aware that the default server configuration has several security weaknesses, which will be addressed in the next exercises:

- **Password-based authentication**: This is susceptible to brute-force attacks.
- **No automatic updates**: Software can become outdated and vulnerable over time.
- **No firewall**: All server ports are potentially exposed to the internet.
- **Unrestricted service access**: Services like databases may be accessible without limitation.

## 4. Server Re-creation and SSH Host Key Management [Exercise 2] {#exercise-2}

This exercise demonstrates what happens when you recreate a server with the same IP address and how to handle SSH host key changes.

### 4.1 Understanding the Problem

When you delete and recreate a server with the same IP address, SSH will detect that the host key has changed. This is a security feature designed to protect against man-in-the-middle attacks.

### 4.2 Recreating Your Server

1. **Delete your current server** but keep both its IPv4 and IPv6 addresses unassigned:
   - In the Hetzner Cloud Console, select your server
   - Click "Delete" 
   - Choose "Keep as unassigned" for both IPv4 and IPv6 addresses
   - Confirm the deletion

2. **Create a new server** reusing the same IP addresses:
   - Create a new server with the same configuration as before
   - During creation, you'll have the option to reuse the unassigned IP addresses

### 4.3 The SSH Host Key Change Warning

When you try to connect to the new server, you'll encounter this warning:

```
$ ssh root@YOUR_SERVER_IP
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:Dg9+vHl/JYIEgYto5AjlwnttzI4yUcgre0c6hXXKkaQ.
Please contact your system administrator.
Add correct host key in /home/user/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /home/user/.ssh/known_hosts:288
Host key for YOUR_SERVER_IP has changed and you have requested strict checking.
```

### 4.4 Why This Happens

- **SSH Host Keys**: Each server generates unique cryptographic keys during installation
- **Known Hosts File**: SSH stores these keys in `~/.ssh/known_hosts` to verify server identity
- **Security Mechanism**: When a host key changes unexpectedly, SSH warns you of potential security risks
- **Legitimate Change**: In this case, the change is expected because you created a new server

### 4.5 Resolving the Issue

**Method 1: Remove the old host key (Recommended for this exercise)**
```sh
ssh-keygen -R YOUR_SERVER_IP
```

**Method 2: Remove the specific line from known_hosts**
```sh
# Open the known_hosts file and remove the line containing your server's IP
vim ~/.ssh/known_hosts
```

**Method 3: Accept the new host key (Use with caution)**
```sh
ssh -o StrictHostKeyChecking=no root@YOUR_SERVER_IP
```

### 4.6 Verification

After resolving the host key issue, you should be able to connect normally:
```sh
ssh root@YOUR_SERVER_IP
```

You should see the new host key being added to your known_hosts file without warnings.
