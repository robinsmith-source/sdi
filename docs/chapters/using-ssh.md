# Using SSH

> This guide covers various aspects of using SSH, from basic connections and managing passphrases with `ssh-agent` to more advanced techniques like host hopping, port forwarding, and X11 forwarding.

## Prerequisites

Before you begin, ensure you have:

- Familiarity with command-line interfaces
- An SSH client:
  - macOS and Linux: Built-in OpenSSH client
  - Windows: Windows Terminal with OpenSSH or PuTTY
- Access to at least one remote server that you can connect to using SSH
- For X11 forwarding exercises (if applicable):
  - macOS: XQuartz installed
  - Windows: Windows Terminal already provides needed utilities
  - Linux: X11 server already included

## 1. Understanding SSH Passphrases

Connecting to remote servers via SSH often involves using SSH keys. If your private SSH key is encrypted with a passphrase, you'll need to enter it for authentication. This is a crucial security measure to protect your private key.

If you manage multiple servers or connect frequently, entering your passphrase for each login can become cumbersome.

```sh
> ssh root@learn.mi.hdm-stuttgart.de
Enter passphrase for key '/home/robin/.ssh/id_ed25519':
root@learn:~# exit
logout
Connection to learn.mi.hdm-stuttgart.de closed.

> ssh root@klausur.mi.hdm-stuttgart.de
Enter passphrase for key '/home/robin/.ssh/id_ed25519':
root@klausur:~# exit
logout
Connection to klausur.mi.hdm-stuttgart.de closed.
```

## 2. Solving the Passphrase Issue with `ssh-agent`

To avoid re-entering your passphrase repeatedly, you can use `ssh-agent`. `ssh-agent` is a background program that holds private keys used for public key authentication. When you add your key to the agent (usually with `ssh-add`), you enter the passphrase once, and the agent caches it for your current session, using it for subsequent SSH connections.

- Install and run `ssh-agent` or a related tool on your system.
- Your passphrase will be cached per login session.
- Optional: Connect your password manager (e.g., KeepassXC provides SSH Agent integration) to the agent for enhanced convenience and management.

The `ssh-agent` typically sets environment variables (like `SSH_AUTH_SOCK`) to let SSH clients know how to communicate with it. It runs as a background process and often uses a Unix domain socket for this communication.

```sh
> printenv | grep SSH_AUTH_SOCK
SSH_AUTH_SOCK=/run/user/21100/keyring/ssh

> ps aux | grep ssh-agent
robin        6671  ... /usr/bin/ssh-agent -D -a /run/user/21100/keyring/.ssh

> ls -al /run/user/21100/keyring/ssh
srwxr-xr-x. 1 robin robin 0 Apr 12 09:58 /run/user/21100/keyring/ssh
```

_Note: The "s" in `srwxr-xr-x` indicates a domain socket._

### `ssh-agent` Installation and Use

1. Ensure `ssh-agent` is running on your system. On many systems, it starts automatically with your desktop session. You can check with `ps aux | grep ssh-agent`.
2. If you haven't already, add your SSH key to the agent:
   ```sh
   ssh-add ~/.ssh/id_ed25519
   ```
   (Replace `~/.ssh/id_ed25519` with the path to your private key if different.)
3. You will be prompted for your passphrase.
4. Try multiple SSH logins to different servers. You should find that entering your passphrase is now required only once (when adding the key to the agent) per login session.

### MI Gitlab Access by SSH

1. Familiarize yourself with GitLab's documentation on using SSH keys: "Use SSH keys to communicate with GitLab".
2. Ensure your public SSH key (the one whose private counterpart is managed by `ssh-agent`) is added to your MI Gitlab profile.
3. Clone a project from your MI GitLab instance to your local machine using the SSH URL (e.g., `git@gitlab.mi.hdm-stuttgart.de:your-group/your-project.git`).
   ```sh
   git clone git@gitlab.mi.hdm-stuttgart.de:your-group/your-project.git
   ```
4. Attempt `git pull` and `git push` operations. These should now proceed without prompting for your SSH key passphrase, thanks to `ssh-agent`.

## 3. Intermediate Host Hopping

Sometimes, you need to connect to a server (Host B) that is only accessible from another server (Host A), not directly from your local machine. This is known as intermediate host hopping or jump hosting.

If you SSH into Host A and then attempt to SSH from Host A to Host B, the connection to Host B might fail if it's expecting public key authentication and cannot access your local SSH agent or keys.

```sh
robin@local> ssh root@learn.mi.hdm-stuttgart.de
Linux learn 6.5.13-1-pve #1 SMP PREEMPT_DYNAMIC PMX 6.5.13-1 (2024-02-05T13:50Z) x86_64
...
root@learn:~# ssh klausur.mi.hdm-stuttgart.de
root@klausur.mi.hdm-stuttgart.de: Permission denied (publickey).
```

To address this, you have a few options:

- **Copy private key to intermediate host (Not Recommended):** You could copy your private key (e.g., `~/.ssh/id_ed25519`) to the intermediate host (Host A). You would then likely need to enter its passphrase again on Host A when connecting to Host B. This method is generally discouraged as it increases the exposure of your private key.
- **Enable Agent Forwarding:** This allows the intermediate host (Host A) to use the `ssh-agent` running on your local machine for authentication to subsequent hosts (Host B).

_Note: Agent forwarding relies on the agent authentication socket (`SSH_AUTH_SOCK`) being available and forwarded from your originating client host._

### Enabling SSH Agent Forwarding

Agent forwarding allows you to use your local SSH keys for authentication even when you are on a remote server, without copying your private keys to that server.

You can enable agent forwarding for a specific host or all hosts in your SSH client configuration file (`~/.ssh/config`) on your local machine.

For a specific host:

```sh
# File ~/.ssh/config on robin@local (your workstation)
...
Host learn.mi.hdm-stuttgart.de # This is Host A, the jump host
  Hostname learn.mi.hdm-stuttgart.de
  User root
  ForwardAgent yes # Forward ssh agent to this remote host.
...
```

With `ForwardAgent yes`, when you SSH to `learn.mi.hdm-stuttgart.de` (Host A), your local `ssh-agent` can be used for authentication when initiating further SSH connections _from_ Host A (e.g., to Host B, `klausur.mi.hdm-stuttgart.de`).

```sh
# On your local machine
robin@local> ssh root@learn.mi.hdm-stuttgart.de
Linux learn 6.5.13-1-pve #1 SMP ...
...
# Now on Host A (learn)
root@learn:~# ssh klausur.mi.hdm-stuttgart.de # Connecting to Host B (klausur)
Linux klausur 6.8.8-4-pve #1 SMP ...
...
root@klausur:~#
```

The connection from `learn` to `klausur` should succeed without a passphrase prompt if the key for `klausur` is in your local `ssh-agent`.

### Exercise 3: SSH Host Hopping

In this exercise, simulate a scenario where Host B is only accessible from Host A.

1. **Setup**:
   - You'll need two remote hosts: Host A (your jump host) and Host B (your target host).
   - Ensure you can SSH into Host A from your local machine using key-based authentication (with your key in `ssh-agent`).
   - Ensure Host B is configured to accept your SSH public key for authentication.
   - For testing, Host B should ideally _not_ be directly accessible from your local machine, or its firewall should block direct SSH from you while allowing it from Host A.
2. **Enable Agent Forwarding**:
   - On your local workstation, edit your `~/.ssh/config` to enable agent forwarding for connections to Host A.
3. **Test Forwarding**:
   - Login to Host A by SSH from your local workstation.
   - From the SSH session on Host A, attempt to SSH into Host B. This connection should now succeed without requiring a passphrase, using your forwarded agent.
4. **Return and Test Direct Access (Control)**:
   - Close both SSH connections, returning to your local workstation.
   - Attempt to login directly to Host B from your local workstation. If it was configured to be inaccessible directly, this should fail, confirming the hop was necessary.
5. **Observe**:
   - Login to Host B (via Host A).
   - While on Host B, try logging in to Host A. What do you observe? Why does this happen? (Hint: Agent forwarding is typically one-way from your client through the jump host.)

## 4. SSH Port Forwarding

SSH port forwarding (also known as SSH tunneling) creates a secure connection that forwards traffic from a port on one machine to a port on another machine, through the SSH connection.

### 4.1. Local Port Forwarding

Local port forwarding (`ssh -L`) makes a port on your local machine forward to a port on a remote machine (or a machine reachable from that remote machine).

This illustrates forwarding a remote web server's port (e.g., port 80 on `remote-server`) to a port on your local machine (e.g., port 2000). Accessing `localhost:2000` in your local browser would then connect to `remote-server:80`.

A common use case is connecting to a database server (e.g., MySQL on port 3306) that is not directly exposed to the internet but is accessible from a server (`HostB`) you can SSH into.

```sh
# Command executed on your local machine:
# Forward local port 2000 to port 3306 on 'localhost' *relative to HostB*.
# 'localhost' here means HostB itself.
ssh -L 2000:localhost:3306 user@HostB
# Replace user@HostB with your actual credentials for the DB's host machine.

# Now, on your local machine, tools can connect to localhost:2000
# and that traffic will be securely forwarded to HostB:3306.
# Example: trying to connect with telnet (output may vary)
$ telnet localhost 2000
Trying ::1...
Connected to localhost.
Escape character is '^]'.
# If HostB's MariaDB server restricts access from 127.0.0.1 (as seen by MariaDB),
# you might see an error like:
# DHost '127.0.0.1' is not allowed to connect to this MariaDB server
```

In this example, connections made to `localhost:2000` on your local machine are tunneled through the SSH connection to `HostB` and then directed to `localhost:3306` from `HostB`'s perspective (i.e., port 3306 on `HostB` itself).

### Exercise 4: SSH Local Port Forwarding

In this exercise, simulate accessing a web server that is firewalled off from direct internet access but reachable via an SSH-accessible host.

1. **Server Setup**:
   - You need a remote server (let's call it `WebServerHost`) running a web server (e.g., Nginx on port 80).
   - Ensure you can SSH into `WebServerHost`.
2. **Initial Check**:
   - Verify if Nginx is directly accessible by navigating to `WebServerHost`'s public IP in a web browser.
3. **Firewall Configuration (Simulated)**:
   - Ideally, configure `WebServerHost`'s firewall to block incoming connections on port 80 from the internet, but allow SSH (port 22). (If you can't modify the firewall, proceed with the understanding that port forwarding provides an alternative access path).
4. **Verify Firewall**:
   - If firewalled, Nginx should no longer be accessible directly via `WebServerHost`'s IP in your browser.
5. **Port Forwarding Setup**:
   - On your local machine, set up local port forwarding. Forward a local port (e.g., 2000) to the web server's port (80) on `WebServerHost`:
     ```sh
     ssh -L 2000:localhost:80 your_user@WebServerHost_IP
     ```
     Replace `your_user@WebServerHost_IP` accordingly. `localhost:80` here refers to port 80 on `WebServerHost` itself.
6. **Test Forwarded Connection**:
   - Open your local web browser and navigate to `http://localhost:2000`. You should now see your Nginx server's default page, served from `WebServerHost` but accessed via your local port 2000.

## 5. X11 Forwarding with SSH

SSH can forward X11 (X Window System) connections. This allows you to run graphical applications on a remote Linux/Unix server and have their graphical user interface (GUI) display on your local machine.

This concept shows running a graphical application like the Firefox browser on the remote server, with its GUI appearing and interacting on your local desktop.

### Exercise 5: SSH X11 Forwarding

In this exercise, you'll run a graphical web browser on a remote server and display its GUI locally, potentially bypassing network restrictions that would prevent direct web access from your local machine to a site accessible from the server.

1. **Prerequisites (Local Machine)**:
   - If you are not on Linux locally, you need an X11 server application installed and running on your local machine (e.g., XQuartz for macOS, VcXsrv or Xming for Windows). Ensure it's configured to allow network connections if necessary.
2. **Server Setup**:
   - You need a remote Linux server (`RemoteGUIServer`) that you can access via SSH.
   - This server should have a desktop environment or at least X11 libraries and the `xauth` package installed.
     ```sh
     # On RemoteGUIServer (example for Debian/Ubuntu)
     sudo apt update
     sudo apt install xauth firefox-esr
     ```
     Installing `firefox-esr` (Extended Support Release) gives you a web browser to test with.
   - Optionally, have a web server (like Nginx) running on `RemoteGUIServer` or another machine accessible _from_ `RemoteGUIServer` but perhaps not directly from your local machine.
3. **Login with X11 Forwarding**:
   - From your local machine, connect to `RemoteGUIServer` using SSH with X11 forwarding enabled. The `-Y` option enables trusted X11 forwarding.
     ```sh
     ssh -Y your_user@RemoteGUIServer_IP
     ```
   - On some systems or SSH configurations, `ForwardX11 yes` and `ForwardX11Trusted yes` in `~/.ssh/config` might also be needed or provide more persistent settings.
4. **Run a Graphical Application**:
   - Once logged into `RemoteGUIServer` via the X11-forwarded SSH session, execute a graphical application from the command line, for example, Firefox:
     ```sh
     firefox-esr &
     ```
     The `&` runs it in the background, freeing your terminal.
5. **Observe**:
   - The Firefox browser GUI should appear on your local desktop.
   - Within this remotely running Firefox, try accessing a website (e.g., `http://localhost` if Nginx is on `RemoteGUIServer`, or any internet site). The web traffic originates from `RemoteGUIServer`.
   - _Note: Launching X11 applications can take some time. Performance depends on network latency and server load._
