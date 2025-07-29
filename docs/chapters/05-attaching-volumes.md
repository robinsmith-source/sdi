# Attaching and Mounting Volumes

> This chapter covers the management of external block storage volumes with Terraform and Cloud-Init. You will learn how to attach a volume, partition it, create file systems, and manage mount points—first manually to understand the process, and then fully automating it for a robust, declarative infrastructure.

## Prerequisites

Before you begin, ensure you have:

- A working Terraform project capable of creating a Hetzner Cloud server, as covered in the previous chapters.
- Familiarity with basic Linux command-line tools for storage management (`fdisk`, `mkfs`, `mount`).
- An understanding of Cloud-Init and how to pass `user_data` to a server.

## External Resources

For more in-depth information on the topics covered in this chapter:

- [Hetzner Cloud Volumes Documentation](https://docs.hetzner.com/cloud/volumes/getting-started/all-you-need-to-know-about-volumes/)
- [fdisk(8) - Linux man page](https://man7.org/linux/man-pages/man8/fdisk.8.html) - Manual for manipulating disk partition tables.
- [fstab(5) - Linux man page](https://man7.org/linux/man-pages/man5/fstab.5.html) - Static information about the filesystems.
- [udevadm(8) - Linux man page](https://man7.org/linux/man-pages/man8/udevadm.8.html) - udev management tool.

::: tip
For comprehensive information about Module concepts, see [Module Concepts](/knowledge/modules).
:::

## 1. Partitions, File Systems, and Mounting [Exercise 15] {#exercise-15}

In this exercise, you will attach a new volume to a server and walk through the manual process of partitioning, formatting, and mounting it. You will then automate these steps to make the mounts persistent across reboots.

### 1.1 Attaching the Volume

::: code-group
```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "hcloud_server" "debian_server" { // [!code focus:36]
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  firewall_ids = [hcloud_firewall.web_access_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "hcloud_volume" "volume01" {
  name      = "volume1"
  size      = 10
  server_id = hcloud_server.debian_server.id
  automount = true
  format    = "xfs"
}
```

```hcl [outputs.tf]
output "volume_id" {
  value       = hcloud_volume.volume01.id
  description = "The volume's id"
}
```
:::

::: details The `automount` Bug and Workaround
Hetzner's `automount` feature can sometimes fail to mount the volume on the first boot. A common workaround is to use Cloud-Init to trigger `udev`, which processes device events. Add this to your `userData.yml` to ensure the volume is recognized.

```yml
#cloud-config
# ... Other non-relevant resources for this exercise ...
runcmd: // [!code focus:3]
  - udevadm trigger -c add -s block -p ID_VENDOR=HC --verbose -p ID_MODEL=Volume
  - reboot # A reboot is often necessary for the automount to take effect
```

The volume will become available only after a system reboot.
:::

### 1.2 Manual Partitioning and Mounting

After rebooting, SSH into your server. The volume will be attached (e.g., at `/dev/sdb`), but you will create your own partitions.

1.  **Identify the volume**: Use `lsblk` or `df -h` to find your attached volume. The auto-mounted volume appears under a path like `/mnt/HC_Volume_<VOLUME_ID>`.
2.  **Unmount the auto-mounted volume**: `sudo umount /mnt/HC_Volume_<VOLUME_ID>` 
    ::: tip
    You can't use `umount` while you're in the volume. Because it appears as busy target.
    :::
3.  **Create two partitions**: Use `sudo fdisk /dev/sdb` to create two new primary partitions (e.g., `/dev/sdb1` and `/dev/sdb2`).
4.  **Format the partitions**: Create an `ext4` and a `xfs` file system.
    ```sh
    sudo mkfs -t ext4 /dev/sdb1
    sudo mkfs -t xfs /dev/sdb2
    ```
5.  **Create mount points**: `sudo mkdir /disk1 /disk2`
6.  **Mount manually**: Mount the first partition by its device name and the second by its UUID.
    ```sh
    sudo mount /dev/sdb1 /disk1
    # Get the UUID for the second partition
    UUID=$(sudo blkid -s UUID -o value /dev/sdb2)
    sudo mount UUID=$UUID /disk2
    ```
7.  **Test**: Create a file in `/disk1`, then `umount` both partitions and see the file disappear.

### 1.3 Persistent Mounting with `fstab`

To make the mounts survive a reboot, you must add them to `/etc/fstab`.

1.  **Edit `/etc/fstab`**: `sudo vim /etc/fstab`
2.  **Add entries**: Add lines for both partitions. Use the device name for the first and the UUID for the second.
    ```fstab
    # <file system> <mount point>   <type>  <options>       <dump>  <pass>
    /dev/sdb1       /disk1          ext4    defaults,nofail 0       2
    UUID=<YOUR_SDB2_UUID> /disk2    xfs    defaults,nofail 0       2
    ```
3.  **Test the configuration**: The command `sudo mount -a` reads `/etc/fstab` and mounts all filesystems not already mounted. Both `/disk1` and `/disk2` should now be mounted.
4.  **Verify**: Reboot the server. After it comes back online, both partitions should be mounted automatically.

## 2. Defining a Custom Mount Point [Exercise 16] {#exercise-16}

In this exercise, you will de-couple the server and volume creation to gain full control over the mounting process. Instead of relying on `automount`, you will use Cloud-Init to format the volume and mount it to a specific, user-defined path like `/volume01`.

### 2.1 De-coupling Server and Volume

Modify your Terraform configuration to create the volume and server independently, then attach them with `automount = false`.

::: code-group
```hcl [main.tf]
# ... Other non-relevant resources for this exercise ...
resource "hcloud_volume" "data_volume" { // [!code focus:36]
  name     = "data-volume"
  size     = 10
  location = var.server_location // [!code ++]
  automount = true // [!code --]
  format   = "xfs"
}

resource "hcloud_server" "debian_server" {
  name         = "debian-server"
  image        = "debian-12"
  server_type  = "cx22"
  location     = var.server_location // [!code ++]
  firewall_ids = [hcloud_firewall.ssh_firewall.id]
  ssh_keys     = [hcloud_ssh_key.user_ssh_key.id]
  user_data    = local_file.user_data.content
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    public_key_robin      = hcloud_ssh_key.user_ssh_key.public_key
    tls_private_key = indent(4, tls_private_key.host.private_key_openssh)
    loginUser       = var.login_user
    volId           = hcloud_volume.data_volume.id // [!code ++]
  })
  filename = "gen/userData.yml"
}

resource "hcloud_volume_attachment" "volume_attachment" { // [!code ++:4]
  volume_id = hcloud_volume.data_volume.id
  server_id = hcloud_server.debian_server.id
}
```

```hcl [variables.tf]
variable "server_location" {
  description = "Location of the server"
  type        = string
  nullable    = false
  default     = "nbg1"
}
```
:::

### 2.2 Automating Mounting with Cloud-Init

Now, modify the `userData.yml` template to format the volume and mount it to a custom path. This approach gives you complete control over the mounting process.

```yml [tpl/userData.yml]
#cloud-config
runcmd:
  - sudo mkdir -p /volume01
  - echo "`/bin/ls /dev/disk/by-id/*${volId}` /volume01 xfs discard,nofail,defaults 0 0" >> /etc/fstab
  - sudo systemctl daemon-reload
  - sudo mount -a
```

This is the same as the previous exercise, but you're using a custom mount point instead of the default `/mnt/HC_Volume_<VOLUME_ID>`.

::: info
- `discard`: Enables TRIM support for SSDs, allowing the filesystem to inform the storage device about unused blocks
- `nofail`: Prevents the system from failing to boot if the volume is not available
- `defaults`: Uses the default mount options (rw, suid, dev, exec, auto, nouser, async)
:::

### 2.3 Verification and Understanding the Process

After running `terraform apply`, SSH into your server and run `df -h`. You should see your volume mounted at `/volume01`, demonstrating that you have successfully taken full control of the volume mounting process.

#### 2.3.1 How the Custom Mounting Works

The key difference in this exercise is the use of the volume ID to dynamically identify the correct device path:

1. **Volume Identification**: The command `/bin/ls /dev/disk/by-id/*${volId}` finds the device path associated with your specific volume ID
2. **Custom Mount Point**: Instead of using Hetzner's default `/mnt/HC_Volume_<ID>` path, you create your own `/volume01` directory
3. **Persistent Mounting**: The entry in `/etc/fstab` ensures the volume mounts automatically on every boot
4. **System Integration**: `systemctl daemon-reload` ensures systemd recognizes the new mount configuration

::: tip
When creating custom mount points, consider using descriptive names that reflect the volume's purpose (e.g., `/data`, `/backups`, `/logs`) rather than generic names like `/volume01`.
:::
