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

For more in-depth technical information about filesystems and volume management:

- [Arch Wiki: Filesystems](https://wiki.archlinux.org/title/File_systems) - Comprehensive guide to Linux filesystems
- [Arch Wiki: Fstab](https://wiki.archlinux.org/title/Fstab) - Detailed explanation of fstab configuration
- [Arch Wiki: XFS](https://wiki.archlinux.org/title/XFS) - XFS filesystem documentation
- [Arch Wiki: Persistent Block Device Naming](https://wiki.archlinux.org/title/Persistent_block_device_naming) - Understanding device naming and identification

These guides provide additional context and complementary information for managing your infrastructure.

::: info
For comprehensive information about volume concepts, see [Volumes](/knowledge/volumes).
:::

## 1. Create a Volume [Exercise 15]

Volumes provide persistent block storage that can be attached to your servers. Here's how to create one:

::: code-group

```hcl [main.tf]
resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.ssh_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
}

resource "hcloud_volume" "data_volume" { //[!code ++:7]
  name      = "data-volume"
  size      = 10
  server_id = hcloud_server.debian_server.id
  automount = true
  format    = "xfs"
}
```

:::

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

::: code-group

```hcl [outputs.tf]
output "server_ip_addr" {
  value       = hcloud_server.debian_server.ipv4_address
  description = "The server's IPv4 address"
}

output "server_datacenter" {
  value       = hcloud_server.debian_server.datacenter
  description = "The server's datacenter"
}

output "volume_id" { // [!code ++:4]
  value       = hcloud_volume.data_volume.id
  description = "The volume's id"
}
```

:::

After applying, you'll see output like:

```sh
terraform apply
...
server_ip_addr="37.27.22.189"
server_datacenter="nbg1-dc3"
volume_id="100723816"
volume_size=10
volume_status="available"
```

## 3. Mount the Volume

There are two approaches to mounting volumes:

### A. Direct Attachment (Recommended)

::: code-group

```hcl [main.tf]
resource "hcloud_volume" "data_volume" { //[!code ++:6]
  name      = "data-volume"
  size      = 10
  automount = true
  format    = "xfs"
}

resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
}

resource "hcloud_volume_attachment" "volume_attachment" { //[!code ++:4]
  volume_id = hcloud_volume.data_volume.id
  server_id = hcloud_server.debian_server.id
}
```

:::

### B. Manual Mounting

If you need more control over the mounting process:

1. Create the volume without automount:

::: code-group

```hcl [main.tf]
resource "hcloud_volume" "data_volume" {
  name      = "data-volume"
  size      = 10
  automount = false //[!code ++]
  format    = "xfs"
}
```

:::

2. Mount manually after attachment:

```sh
sudo mkdir -p /mnt/data-volume
sudo mount /dev/disk/by-id/scsi-0HC_Volume_${VOLUME_ID} /mnt/data-volume
```

## 4. Managing Mount Points [Exercise 16]

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
/dev/sdb        10475520  106088  10369432   2% /data-volume
```

### Setting a Specific Mount Point

To explicitly set the mount point to `/data-volume` and avoid dependency cycles:

1. Create volume and server independently with matching locations:

::: code-group

```hcl [main.tf]
resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.ssh_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "hcloud_volume" "data_volume" {
  name      = "data-volume"
  size      = 10
  location  = "nbg1"
  automount = false
  format    = "xfs"
}
```

:::

2. Attach volume to server:

::: code-group

```hcl [main.tf]
resource "hcloud_volume_attachment" "volume_attachment" {
  volume_id = hcloud_volume.data_volume.id
  server_id = hcloud_server.debian_server.id
}
```

:::

3. Configure the mount point using cloud-init:

::: code-group

```hcl [main.tf]
resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    public_key = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key  = indent(4, tls_private_key.host.private_key_openssh)
    loginUser        = "devops"
    volId = hcloud_volume.data_volume.id //[!code ++]
  })
  filename = "gen/userData.yml"
}
```

```yml [tpl/userData.yml]
runcmd:
  - sudo mkdir -p /data-volume
  - echo "`/bin/ls /dev/disk/by-id/*${volId}` /data-volume xfs discard,nofail,defaults 0 0" | sudo tee -a /etc/fstab [!code focus]
  - sudo systemctl daemon-reload
  - sudo mount -a
```

:::

4. After applying, verify the mount:

```sh
cat /etc/fstab
```

You should see an entry like:

```sh
/dev/disk/by-id/scsi-0HC_Volume_102593604 /data-volume xfs defaults 0 0
```

The `/etc/fstab` file controls automatic mounting. Here's a typical entry:

```sh
/dev/disk/by-id/scsi-0HC_Volume_102593604 /data-volume xfs discard,nofail,defaults 0 0
```

Options explained:

- `discard`: Enables TRIM support
- `nofail`: Prevents boot failure if volume is unavailable
- `defaults`: Standard mount options
- `0 0`: Dump and fsck options (0 means disabled)
