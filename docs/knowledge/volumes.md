# Volumes <Badge type="info" text="Unix" />

> Volumes and mounts are fundamental concepts in Unix-like systems for managing storage and making it accessible to the operating system and applications. They provide a way to organize and access data across different storage devices and filesystems.

::: info Purpose
Volumes and mounts enable:

- Persistent storage beyond container/VM lifecycle
- Data sharing between containers and hosts
- Storage management and organization
- Backup and recovery capabilities
  :::

## Core Concepts {#core-concepts}

### What is a Volume?

A volume is a storage unit that can be:

- A physical disk partition
- A logical volume (LVM)
- A virtual disk
- A container volume

### Mounts

Mounting is the process of making a filesystem accessible at a specific point in the directory tree.

::: details Mount Points
A mount point is a directory where a filesystem is attached. Common mount points include:

- `/` (root filesystem)
- `/home` (user home directories)
- `/var` (variable data)
- `/mnt` (temporary mount points)
- `/media` (removable media)
  :::

## Essential Commands <Badge type="tip" text="Core CLI" />

```sh
# List all block devices and their mount points
lsblk
# Show all currently mounted filesystems
mount
# Alternative way to view mounts
cat /proc/mounts
# Show disk space usage
df -h
# Mount a filesystem
mount /dev/sdb1 /mnt/data
# Mount with specific options
mount -o ro,noexec /dev/sdb1 /mnt/data
# Unmount a filesystem
umount /mnt/data
# Force unmount if busy
umount -f /mnt/data
# Create a new filesystem
mkfs.ext4 /dev/sdb1
# Check filesystem for errors
fsck /dev/sdb1
# Resize an ext4 filesystem
resize2fs /dev/sdb1
```

## Best Practices

- Use appropriate mount options for your use case
- Choose the right filesystem for your needs (`ext4`, `XFS`, `Btrfs`, `ZFS`)
- Use LVM for flexible storage management
- Set proper permissions on mount points
- Monitor disk usage and set up alerts
- Consider encryption for sensitive data

## Common Use Cases

- **Container Volumes:**
  - `docker volume create mydata`
  - `docker run -v mydata:/data myapp`
- **Backup Storage:**
  - Mount backup drives and set up `/etc/fstab`
- **Shared Storage:**
  - NFS: `mount -t nfs server:/share /mnt/share`
  - CIFS/SMB: `mount -t cifs //server/share /mnt/share -o username=user`

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details Mount Point Busy

- Find processes using the mount point: `lsof /mnt/data`
- Force unmount if necessary: `umount -f /mnt/data`
  :::

::: details Filesystem Errors

- Unmount the filesystem: `umount /dev/sdb1`
- Check and repair: `fsck /dev/sdb1`
- Remount: `mount /dev/sdb1 /mnt/data`
  :::

::: details LVM Issues

- Scan for LVM components: `pvscan`, `vgscan`, `lvscan`
- Repair volume group: `vgck myvg`
  :::

---

For more detailed information about volumes and mounts in Unix systems, refer to the [Linux Documentation Project](https://tldp.org/) and your distribution's specific documentation.
