# Volumes

> In Unix-like systems (like Linux), "volumes" are storage areas, and "mounts" are how you make them accessible. A volume is like a hard drive or partition, and mounting is connecting it to a specific folder on your system so you can use it.

## Core Concepts {#core-concepts}

A volume is a dedicated space for storing data. It can be a physical disk partition, logical volume (LVM), virtual disk, or container volume. Mounting connects a filesystem (on a volume) to a specific directory in your operating system's structure, making its data accessible.

### Key Concepts Explained

::: details Volume Types

- **Physical Disk Partition**: A section of a physical hard drive
- **Logical Volume (LVM)**: Flexible storage management with volume groups
- **Virtual Disk**: Storage allocated by virtualization platforms
- **Container Volume**: Persistent storage for containerized applications
  :::

::: details Mount Points
The directory where a filesystem is attached. Common examples include:

- `/` (root): The main filesystem
- `/home`: User home directories
- `/var`: Variable data files
- `/mnt`: Temporary mount points
- `/media`: Removable media
  :::

::: details Filesystem Types

- **ext4**: Modern Linux filesystem with journaling
- **XFS**: High-performance filesystem for large files
- **Btrfs**: Advanced filesystem with snapshots and RAID
- **NTFS**: Windows filesystem (readable on Linux)
- **FAT32**: Simple filesystem for compatibility
  :::

## Essential Commands <Badge type="tip" text="Core CLI" />

### Volume and Mount Management

```sh
# List all block devices and mount points
lsblk

# Show all currently mounted filesystems
mount

# Alternative way to view mounts
cat /proc/mounts

# Show disk space usage
df -h

# Mount a filesystem
mount /dev/sdb1 /mnt/data

# Mount with specific options (e.g., read-only, no execution)
mount -o ro,noexec /dev/sdb1 /mnt/data

# Unmount a filesystem
umount /mnt/data

# Force unmount if busy (use with caution)
umount -f /mnt/data
```

### Filesystem Operations

```sh
# Create a new ext4 filesystem
mkfs.ext4 /dev/sdb1

# Check filesystem for errors
fsck /dev/sdb1

# Resize an ext4 filesystem
resize2fs /dev/sdb1

# Format with different filesystem
mkfs.xfs /dev/sdb1
mkfs.btrfs /dev/sdb1
```

### LVM Commands

```sh
# Create physical volume
pvcreate /dev/sdb

# Create volume group
vgcreate myvg /dev/sdb

# Create logical volume
lvcreate -L 10G -n mylv myvg

# Extend logical volume
lvextend -L +5G /dev/myvg/mylv

# Resize filesystem after extending
resize2fs /dev/myvg/mylv
```

## Best Practices

- Use appropriate mount options for your use case
- Choose the right filesystem for your workload
- Consider LVM for flexible storage management
- Set proper permissions on mount points
- Monitor disk usage regularly
- Consider encryption for sensitive data
- Use UUIDs in `/etc/fstab` for reliability
- Implement proper backup strategies

## Common Use Cases

- **Container Volumes**: Persistent storage for Docker containers
- **Backup Storage**: Mounting drives for backups
- **Shared Storage**: Setting up network filesystems (NFS, CIFS/SMB)
- **Database Storage**: Dedicated volumes for database files
- **Log Storage**: Separate volumes for log files
- **Media Storage**: Large volumes for media files

## Troubleshooting <Badge type="warning" text="Common Issues" />

::: details Mount Point Busy
Find processes using `lsof /mnt/data`. Force unmount with `umount -f` (use caution). Check for open files and processes.
:::

::: details Filesystem Errors
Unmount the filesystem (`umount`), check/repair (`fsck`), then remount. Backup data before running filesystem checks.
:::

::: details LVM Issues
Scan for components (`pvscan`, `vgscan`, `lvscan`). Check volume group (`vgck`). Verify physical volume status.
:::

::: details Permission Denied
Check mount options and filesystem permissions. Verify user/group ownership. Ensure proper access rights.
:::

::: details Disk Space Issues
Use `df -h` to check space usage. Clean up unnecessary files. Consider extending volumes if possible.
:::
