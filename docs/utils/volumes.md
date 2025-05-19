# Volumes <Badge type="info" text="Unix" />

> Volumes and mounts are fundamental concepts in Unix-like systems for managing storage and making it accessible to the operating system and applications. They provide a way to organize and access data across different storage devices and filesystems.

::: info Purpose
Volumes and mounts enable:
- Persistent storage beyond container/VM lifecycle
- Data sharing between containers and hosts
- Storage management and organization
- Backup and recovery capabilities
:::

## Core Concepts {#core-workflow}

### Volumes
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

### Listing and Information

```sh
# List all block devices and their mount points
lsblk

# Show all currently mounted filesystems
mount

# Alternative way to view mounts
cat /proc/mounts

# Show disk space usage
df -h
```

### Mounting and Unmounting

```sh
# Mount a filesystem
mount /dev/sdb1 /mnt/data

# Mount with specific options
mount -o ro,noexec /dev/sdb1 /mnt/data

# Unmount a filesystem
umount /mnt/data

# Force unmount if busy
umount -f /mnt/data
```

### Filesystem Operations

```sh
# Create a new filesystem
mkfs.ext4 /dev/sdb1

# Check filesystem for errors
fsck /dev/sdb1

# Resize an ext4 filesystem
resize2fs /dev/sdb1
```

## LVM (Logical Volume Management) <Badge type="info" text="Advanced" />

LVM provides a more flexible way to manage storage by abstracting physical storage into logical volumes.

### Basic LVM Concepts

::: details Physical Volume (PV)
A physical storage device (disk or partition) that has been initialized for use with LVM.
:::

::: details Volume Group (VG)
A collection of physical volumes that are combined into a single storage unit.
:::

::: details Logical Volume (LV)
A virtual partition created from a volume group. Can be resized dynamically.
:::

### LVM Operations

```sh
# Initialize a disk for LVM
pvcreate /dev/sdb

# Create a volume group
vgcreate myvg /dev/sdb

# Create a logical volume
lvcreate -L 10G -n mylv myvg

# Extend a logical volume
lvextend -L +5G /dev/myvg/mylv
```

### LVM Information

```sh
# List physical volumes
pvdisplay

# List volume groups
vgdisplay

# List logical volumes
lvdisplay

# Scan for LVM components
pvscan
vgscan
lvscan
```

## Best Practices

### Mount Options
- Use appropriate mount options for your use case
- Consider `noexec`, `nosuid` for security
- Use `defaults` for standard mounting

### Filesystem Choice
- `ext4`: General purpose, well-tested
- `XFS`: High performance, good for large files
- `Btrfs`: Advanced features, snapshots
- `ZFS`: Enterprise-grade, advanced features

### LVM Usage
- Use LVM for flexible storage management
- Create separate volume groups for different purposes
- Leave space for future expansion

### Security
- Set proper permissions on mount points
- Use mount options to restrict access
- Consider encryption for sensitive data

### Monitoring
- Monitor disk usage with `df` and `du`
- Set up alerts for low disk space
- Regularly check filesystem health

## Common Use Cases

### Container Volumes
```sh
# Docker volume creation
docker volume create mydata

# Mount volume to container
docker run -v mydata:/data myapp
```

### Backup Storage
```sh
# Mount backup drive
mount /dev/sdb1 /mnt/backup

# Set up automatic mounting
echo "/dev/sdb1 /mnt/backup ext4 defaults 0 2" >> /etc/fstab
```

### Shared Storage
```sh
# NFS mount
mount -t nfs server:/share /mnt/share

# CIFS/SMB mount
mount -t cifs //server/share /mnt/share -o username=user
```

## Troubleshooting <Badge type="warning" text="Common Issues" />

### Mount Point Busy
If a mount point is busy when trying to unmount:
```sh
# Find processes using the mount point
lsof /mnt/data

# Force unmount (use with caution)
umount -f /mnt/data
```

### Filesystem Errors
If filesystem errors are detected:
```sh
# Unmount the filesystem
umount /dev/sdb1

# Check and repair
fsck /dev/sdb1

# Remount
mount /dev/sdb1 /mnt/data
```

### LVM Issues
Common LVM problems and solutions:
```sh
# Check physical volumes
pvscan

# Check volume groups
vgscan

# Check logical volumes
lvscan

# Repair volume group
vgck myvg
```

---

For more detailed information about volumes and mounts in Unix systems, refer to the [Linux Documentation Project](https://tldp.org/) and your distribution's specific documentation.
