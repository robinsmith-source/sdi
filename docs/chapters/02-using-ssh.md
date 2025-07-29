# Using SSH

> This chapter covers various aspects of using SSH, from basic connections and managing passphrases with `ssh-agent` to more advanced techniques like host hopping, port forwarding, and X11 forwarding.

## Prerequisites

Before you begin, ensure you have:

- A Hetzner Cloud account.
- At least one server created in the Hetzner Cloud Console.
- For X11 forwarding exercises (if applicable):
  - macOS: XQuartz installed
  - Windows: Windows Terminal already provides needed utilities
  - Linux: X11 server already included

## External Resources

For more in-depth information about SSH and related topics:

- [OpenSSH Manual](https://www.openssh.com/manual.html) - Official OpenSSH documentation
- [Arch Wiki: SSH](https://wiki.archlinux.org/title/SSH) - Comprehensive SSH guide
- [Arch Wiki: SSH Keys](https://wiki.archlinux.org/title/SSH_keys) - Detailed SSH key management
- [Arch Wiki: SSH/Config](https://wiki.archlinux.org/title/SSH/Config) - SSH client configuration
- [Arch Wiki: X11 Forwarding](https://wiki.archlinux.org/title/X11_forwarding) - X11 forwarding guide
- [GitHub: Using SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) - GitHub SSH key documentation

::: tip
For comprehensive information about SSH concepts, see [SSH Concepts](/knowledge/ssh).
:::

## 1. Improving Server Security [Exercise 3] {#exercise-3}

In this exercise, you will improve the security of your server by implementing SSH key authentication and configuring a restrictive firewall. This builds upon the basic server creation from the previous chapter and introduces important security concepts.

### 1.1 Creating a Restrictive Firewall

This exercise builds upon the firewall creation from the [Hetzner Cloud chapter](/chapters/01-hetzner-cloud#exercise-1#_2-configuring-a-firewall).
Instead of allowing all traffic, you will create a more restrictive firewall that only allows specific protocols like ICMP.

| IP Version          | Protocol | Port |
| ------------------- | -------- | ---- |
| Any IPv4 / Any IPv6 | ICMP     | -    |

::: info
The port field is left empty because ICMP is a protocol that doesn't use ports.
:::

### 1.2 Adding SSH Key Authentication

1. In the left-hand navigation panel, select `Security`, then click `SSH Keys`.
2. Add your public SSH key to your Hetzner account, marking it as "default" and giving it a descriptive name.

::: details How to retrieve my public SSH key?

```sh
cat ~/.ssh/id_ed25519.pub
```

If you are using a different key, replace `id_ed25519` with the name of your key file.

:::

### 1.3 Recreating the Server with Enhanced Security

1. Select both your newly created firewall and your SSH key during server creation.

::: info
The subsequent examples assume a `167.235.54.109` server IP.
:::

### 1.4 Testing Connectivity

1. **Try to ping your server**:

   ```sh
   ping 167.235.54.109
   PING 167.235.54.109 (167.235.54.109) 56(84) bytes of data.
   64 bytes from 167.235.54.109: icmp_seq=1 ttl=54 time=13.2 ms
   64 bytes from 167.235.54.109: icmp_seq=2 ttl=54 time=12.3 ms
   ```

2. **Due to your firewall rule, SSH access should fail** initially, because of the missing SSH rule in the deny-all firewall.

3. **After adding the SSH rule, SSH password-less access should work**:
   ```sh
   ssh root@167.235.54.109
   ```

### 1.5 Server Setup and Testing

1. **Update and reboot your server**:

   ```sh
   root@gtest3:~# apt update
   root@gtest3:~# apt upgrade
   root@gtest3:~# aptitude -y upgrade
   root@gtest3:~# reboot
   ```

2. **Install the Nginx web server**:

   ```sh
   root@gtest3:~# apt install nginx
   ```

3. **Check for the running process**:

   ```sh
   root@gtest3:~# systemctl status nginx
   ● nginx.service - A high performance web server and a reverse proxy server
        Loaded: loaded (/lib/systemd/system/nginx.service; enabled; preset: enabled)
        Active: active (running) since Tue 2024-06-04 08:24:57 UTC; 1min 31s ago
   ```

4. **Use an SSH connection to access the server and verify HTTP (port 80) accessibility from your server**:

   ```sh
   # ssh root@167.235.54.109
   root@gtest3:~# wget -O - http://167.235.54.109
   --2024-06-04 09:02:41--  http://167.235.54.109/
   Connecting to 167.235.54.109:80... connected.
   HTTP request sent, awaiting response... 200 OK
   Length: 615 [text/html]
   Saving to: 'STDOUT'

   <html>
   <head>
   <title>Welcome to nginx!</title>
           ...
   <p><em>Thank you for using nginx.</em></p>
   </body>
   </html>
   ```

5. **Try external access using http://167.235.54.109 again in your browser of choice**.

::: details Why does external access fail although local access from the server itself works?

The external access fails because the firewall is blocking all traffic except for the SSH rule.
:::

6. **Modify your firewall by adding an inbound HTTP traffic rule and try again accessing http://167.235.54.109 in your browser**.

::: details How to modify the firewall?

1. On the left-hand side, select `Firewalls`, then click on the `Edit` button for the firewall you want to modify (in this case the one you created in the previous exercise).
2. Add a new rule with the following settings:

| IP Version          | Protocol | Port |
| ------------------- | -------- | ---- |
| Any IPv4 / Any IPv6 | HTTP     | 80   |

3. Click on the `Save` button to apply the changes.

You should now be able to access the server from the outside using a web browser pointing to the server's IP address.

## 2. SSH Agent Installation [Exercise 4] {#exercise-4}

In this exercise, you will learn how to use `ssh-agent` to avoid entering your SSH key passphrase repeatedly.

### 2.1 Understanding ssh-agent

To avoid re-entering your passphrase repeatedly, you can use `ssh-agent`. `ssh-agent` is a background program that holds private keys used for public key authentication. When you add your key to the agent (usually with `ssh-add`), you enter the passphrase once, and the agent caches it for your current session, using it for subsequent SSH connections.

The `ssh-agent` typically sets environment variables (like `SSH_AUTH_SOCK`) to let SSH clients know how to communicate with it. It runs as a background process and often uses a Unix domain socket for this communication.

```sh
> printenv | grep SSH_AUTH_SOCK
SSH_AUTH_SOCK=/run/user/21100/keyring/ssh

> ps aux | grep ssh-agent
robin        6671  ... /usr/bin/ssh-agent -D -a /run/user/21100/keyring/.ssh

> ls -al /run/user/21100/keyring/ssh
srwxr-xr-x. 1 robin robin 0 Apr 12 09:58 /run/user/21100/keyring/ssh
```

::: tip
The `SSH_AUTH_SOCK` environment variable points to the socket used by `ssh-agent`.
This socket is used by SSH clients to communicate with the agent. The `ls -al` command shows the socket file, which has permissions `srwxr-xr-x`. The `s` in `srwxr-xr-x` indicates a domain socket.
:::

### 2.2 Installation and Use

1. Ensure `ssh-agent` is running on your system. On many systems, it starts automatically with your desktop session. You can check with `ps aux | grep ssh-agent`.
2. If you haven't already, add your SSH key to the agent:
   ```sh
   ssh-add ~/.ssh/id_ed25519
   ```
   (Replace `~/.ssh/id_ed25519` with the path to your private key if different.)
3. You will be prompted for your passphrase.
4. Try multiple SSH logins to different servers. You should find that entering your passphrase is now required only once (when adding the key to the agent) per login session.

## 3. GitLab Access via SSH [Exercise 5] {#exercise-5}

In this exercise, you will configure SSH access to GitLab repositories, which is essential for secure version control operations. This builds upon the SSH agent setup from the previous exercise.

1. **Read the [GitLab SSH documentation](https://docs.gitlab.com/ee/user/ssh.html)** to understand SSH key configuration.
2. **Add your public SSH key** (the one whose private counterpart is managed by `ssh-agent`) to your MI GitLab profile.
3. **Clone a project using SSH**:
   ```sh
   git clone git@gitlab.mi.hdm-stuttgart.de:your-group/your-project.git
   ```
4. **Test Git operations**: Try `git push` and `git pull` operations. These should proceed without prompting for your SSH key passphrase, thanks to `ssh-agent`.

::: info
This SSH configuration is also applicable for GitHub and other Git hosting services. You can find more information in the [GitHub SSH key guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).
:::

## 4. Intermediate Host Hopping [Exercise 6] {#exercise-6}

In this exercise, you will learn about SSH agent forwarding, which allows you to access a `Host B` that is only reachable through `Host A`. This is a common scenario in enterprise networks where servers are in restricted subnets.

1. **Create two hosts A and B** with SSH key access being enabled for both of your group.
2. **Enable agent forwarding** from your local workstation to `host A`.
3. **Login to `host A`** by SSH.
4. **Continue login to `host B`**.
5. **Close both connections**, thus getting back to your workstation.
6. **Login to `host B`**.
7. **Still on B, try logging in to Host A**.

### 4.1 Understanding the Problem

Sometimes, you need to connect to a server (`Host B`) that is only accessible from another server (`Host A`), not directly from your local machine. This is known as intermediate host hopping or jump hosting.

If you SSH into `Host A` and then attempt to SSH from `Host A` to `Host B`, the connection to `Host B` might fail if it's expecting public key authentication and cannot access your local SSH agent or keys.

```sh
# On your local machine
robin@local> ssh root@learn.mi.hdm-stuttgart.de # Connect to host A
Linux learn 6.5.13-1-pve
...
# Now on Host A (learn)
root@learn:~# ssh klausur.mi.hdm-stuttgart.de # Connect to host B from host A
root@klausur.mi.hdm-stuttgart.de: Permission denied (publickey).
```

### 4.2 Enabling SSH Agent Forwarding

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

With `ForwardAgent yes`, when you SSH to `learn.mi.hdm-stuttgart.de` (`Host A`), your local `ssh-agent` can be used for authentication when initiating further SSH connections _from_ `Host A` (e.g., to `Host B`, `klausur.mi.hdm-stuttgart.de`).

```sh
# On your local machine
robin@local> ssh root@learn.mi.hdm-stuttgart.de # Connect to host A
Linux learn 6.5.13-1-pve
...
# Now on Host A (learn)
root@learn:~# ssh klausur.mi.hdm-stuttgart.de # Connect to Host B (klausur)
Linux klausur 6.8.8-4-pve
...
root@klausur:~#
```

The connection from `learn` to `klausur` should succeed without a passphrase prompt if the key for `klausur` is in your local `ssh-agent`.

## 5. SSH Port Forwarding [Exercise 7] {#exercise-7}

In this exercise, you will learn about SSH tunneling (port forwarding), which allows you to securely access services on a remote server even when direct access is blocked by firewalls.

1. **Create a server** like in [Exercise 3](#exercise-3).
2. **Check for Nginx accessibility** by visiting your server's IP in a web browser.
3. **Configure your firewall** to allow SSH access only (remove any HTTP rules from the firewall).
4. **Nginx should no longer be accessible** from external sources.
5. **Forward port 80 of your remote host to port 2000 on your local workstation**:
   ```sh
   ssh -L 2000:localhost:80 root@YOUR_SERVER_IP
   ```
6. **Point your browser to `http://localhost:2000`** - you should now see your Nginx server's content.

### 5.1 Understanding SSH Port Forwarding

SSH port forwarding (also known as SSH tunneling) creates a secure connection that forwards traffic from a port on one machine to a port on another machine, through the SSH connection.

The `-L 2000:localhost:80` parameter means:

- `2000`: Local port on your machine
- `localhost:80`: Remote port on the server (localhost from the server's perspective)
- The connection is tunneled through the SSH connection to `YOUR_SERVER_IP`

## 6. SSH X11 Forwarding [Exercise 8] {#exercise-8}

In this exercise, you will learn about X11 forwarding, which allows you to run graphical applications on a remote server and display them on your local machine.

1. **Create a server** like in [Exercise 3](#exercise-3).
2. **Check for Nginx accessibility** by visiting your server's IP in a web browser.
3. **Configure your firewall** to allow SSH access only.
4. **Nginx should no longer be accessible** from external sources.
5. **Access your remote host and install the xauth package**:
   ```sh
   apt install xauth
   ```
6. **Re-login to your remote host using SSH's -Y option for X11 forwarding**:
   ```sh
   ssh -Y root@YOUR_SERVER_IP
   ```
   ::: tip
   Unless you are on Linux, you may need to install an X11 server locally (e.g., XQuartz on macOS).
   :::
7. **Install the Firefox browser on your remote server**:
   ```sh
   apt install firefox-esr
   ```
8. **Execute the Firefox browser on your remote host, connecting the GUI to your local desktop**:

   ```sh
   firefox-esr &
   ```

   You should now be able to access your Nginx server through the Firefox browser.

   ::: info
   This might take some time, especially on slower server instances.
   :::

### 6.1 Understanding X11 Forwarding

SSH can forward X11 (X Window System) connections. This allows you to run graphical applications on a remote Linux/Unix server and have their graphical user interface (GUI) display on your local machine.

The `-Y` option enables trusted X11 forwarding, which allows the remote application to access your local X11 server and display its GUI on your desktop.
