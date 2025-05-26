# Attaching Volumes

> This guide provides a comprehensive walkthrough for managing volumes in your infrastructure using Terraform. It covers volume creation, attachment, mounting, and management best practices.

## Prerequisites

Before you begin, ensure you have:

- Basic understanding of volumes and mounts under Unix/Linux systems
- Familiarity with command-line interfaces
- Terraform installed and configured
- Access to your cloud provider's credentials
- An SSH client:
    - macOS and Linux: Built-in OpenSSH client
    - Windows: Windows Terminal with OpenSSH or PuTTY

## External Resources

For in-depth technical information about filesystems and volume management:

- [Arch Wiki: Filesystems](https://wiki.archlinux.org/title/File_systems) - Comprehensive guide to Linux filesystems
- [Arch Wiki: Fstab](https://wiki.archlinux.org/title/Fstab) - Detailed explanation of fstab configuration
- [Arch Wiki: XFS](https://wiki.archlinux.org/title/XFS) - XFS filesystem documentation
- [Arch Wiki: Persistent Block Device Naming](https://wiki.archlinux.org/title/Persistent_block_device_naming) - Understanding device naming and identification

These guides provide additional context and complementary information for managing your infrastructure.

## 1. Create a Volume

Volumes provide persistent block storage that can be attached to your servers. Here's how to create one:

```hcl
resource "hcloud_server" "basicServer" {
  name         = "basicServer"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.sshFw.id]
  ssh_keys     = [hcloud_ssh_key.loginRobin.id]
}

resource "hcloud_volume" "volume01" {
  name      = "volume01"
  size      = 10
  server_id = hcloud_server.basicServer.id
  automount = true
  format    = "xfs"
}
```

Let's break down the volume configuration:

- `name`: A unique identifier for your volume
- `size`: Size in GB (10GB in this example)
- `server_id`: The ID of the server to attach the volume to
- `automount`: When set to `true`, automatically mounts the volume to the filesystem
- `format`: The filesystem type (xfs is recommended for its performance and reliability)

### Volume Types and Considerations

- **Size**: Choose based on your needs, but consider future growth
- **Format**:
  - `xfs`: High-performance 64-bit journaling filesystem (recommended)
  - `ext4`: Traditional Linux filesystem
  - `ext3`: Legacy filesystem (not recommended for new deployments)

## 2. Investigate Volume Details

To verify your volume creation and get its details:

```hcl
output "volume_id" {
  value       = hcloud_volume.volume01.id
  description = "The volume's id"
}
```

After applying, you'll see output like:

```sh
terraform apply
...
hello_ip_addr="37.27.22.189"
volume_id="100723816"
volume_size=10
volume_status="available"
```

## 3. Mount the Volume

There are two approaches to mounting volumes:

### A. Direct Attachment (Recommended)

```hcl
resource "hcloud_volume" "volume01" {
  name      = "volume01"
  size      = 10
  automount = true
  format    = "xfs"
}

resource "hcloud_server" "server01" {
  name         = "server01"
  image        = "debian-12"
  server_type  = "cx22"
}

resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.volume01.id
  server_id = hcloud_server.server01.id
}
```

### B. Manual Mounting

If you need more control over the mounting process:

1. Create the volume without automount:

```hcl
resource "hcloud_volume" "volume01" {
  name      = "volume1"
  size      = 10
  automount = false
  format    = "xfs"
}
```

2. Mount manually after attachment:

```sh
sudo mkdir -p /mnt/volume01
sudo mount /dev/disk/by-id/scsi-0HC_Volume_${VOLUME_ID} /mnt/volume01
```

## 4. Managing Mount Points

### Viewing Current Mounts

Check your current mount points:

```sh
df -h
```

Example output:

```sh
Filesystem     1K-blocks    Used Available Use% Mounted on
udev             1933340       0   1933340   0% /dev
tmpfs             391088     652    390436   1% /run
/dev/sda1       39052844 2157152  35259124   6% /
/dev/sdb        10475520  106088  10369432   2% /volume01
```

### Setting a Specific Mount Point

To explicitly set the mount point to `/volume01` and avoid dependency cycles:

1. Create volume and server independently with matching locations:

```hcl
resource "hcloud_server" "basicServer" {
  name         = "basicServer"
  image        = "debian-12"
  server_type  = "cx22"
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.sshFw.id]
  ssh_keys     = [hcloud_ssh_key.loginRobin.id]
  user_data    = local_file.user_data.content
}

resource "hcloud_volume" "volume01" {
  name      = "volume01"
  size      = 10
  location  = "nbg1"
  automount = false
  format    = "xfs"
}
```

2. Attach volume to server:

```hcl
resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.volume01.id
  server_id = hcloud_server.basicServer.id
}
```

3. Configure the mount point using cloud-init:

```hcl
resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    public_key_robin = hcloud_ssh_key.loginRobin.public_key
    tls_private_key  = indent(4, tls_private_key.host.private_key_openssh)
    loginUser        = "devops"
    volId = hcloud_volume.volume01.id
  })
  filename = "gen/userData.yml"
}
```

```yml
runcmd:
  - sudo mkdir -p /volume01
  - echo "`/bin/ls /dev/disk/by-id/*${volId}` /volume01 xfs discard,nofail,defaults 0 0" | sudo tee -a /etc/fstab
  - sudo systemctl daemon-reload
  - sudo mount -a
```

4. After applying, verify the mount:

```sh
cat /etc/fstab
```

You should see an entry like:
```sh
/dev/disk/by-id/scsi-0HC_Volume_102593604 /volume01 xfs defaults 0 0
```

The `/etc/fstab` file controls automatic mounting. Here's a typical entry:

```sh
/dev/disk/by-id/scsi-0HC_Volume_102593604 /volume01 xfs discard,nofail,defaults 0 0
```

Options explained:

- `discard`: Enables TRIM support
- `nofail`: Prevents boot failure if volume is unavailable
- `defaults`: Standard mount options
- `0 0`: Dump and fsck options (0 means disabled)
