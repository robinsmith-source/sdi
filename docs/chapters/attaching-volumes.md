# Attaching Volumes

> This guide provides a step-by-step process for attaching volumes to your server using Terraform. It covers the creation of a volume, investigating its details, and mounting it to the server.

## Prequisites

Before you begin, ensure you have:

- Foreknowledge of volumes and mounts under Unix
- Familiarity with command-line interfaces
- An SSH client:
    - macOS and Linux: Built-in OpenSSH client
    - Windows: Windows Terminal with OpenSSH or PuTTY

## 1. Create a volume

```hcl
resource "hcloud_server" "helloServer" {
  server_type  =  "cx22"
}

resource "hcloud_volume" "volume01" {
  name      = "volume1"
  size      = 10
  server_id = hcloud_server.helloServer.id
  automount = true
  format    = "xfs"
}
```

With this snippet we create a volume bound to the server. It has:
- a size of 10GB
- `automount` set to true, to automatically attach the volume to the file system
- format set to `xfs`, which stands for Extents File System, a high-performance 64-bit journaling file system

## 2. Investigate volume details

::: code-group

```hcl [main.tf]
output "volume_id" {
 value       = hcloud_volume.volume01.id
 description = "The volume's id"
}
```

```sh [output]
terraform apply
...
hello_ip_addr="37.27.22.189"
volume_id="100723816"
```

:::

## 3. Mount the volume

```hcl
resource "hcloud_volume" "volume01" {
  name      = "volume1"
  size      = 10
  automount = true
  format    = "xfs"
}

resource "hcloud_server" "server01" {
  user_data = templatefile(
    "userData.yml.tpl", {
       volId=hcloud_volume.volume01.id
  }) 
}
resource "hcloud_volume_attachment" "main" {
  volume_id=hcloud_volume.volume01.id
  server_id=hcloud_server.server01.id
}
```

## 4. Change mount point name

::: code-group

```sh [/etc/fstab]
devops@hello:~$ cat /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# systemd generates mount units based on this file, see systemd.mount(5).
# Please run 'systemctl daemon-reload' after making changes here.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/sda3 during installation
UUID=4c2d0dc3-ba79-420b-9e28-e33f40424775 /               ext4    errors=remount-ro 0       1
# /boot/efi was on /dev/sda2 during installation
UUID=490A-B31D  /boot/efi       vfat    umask=0077      0       1
/dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0
/dev/disk/by-id/scsi-0HC_Volume_102593604 /volume01 xfs discard,nofail,defaults 0 0
```


```sh [df]
devops@hello:~$ df
Filesystem     1K-blocks    Used Available Use% Mounted on
udev             1933340       0   1933340   0% /dev
tmpfs             391088     652    390436   1% /run
/dev/sda1       39052844 2157152  35259124   6% /
tmpfs            1955424       0   1955424   0% /dev/shm
tmpfs               5120       0      5120   0% /run/lock
/dev/sda15        245969     138    245832   1% /boot/efi
/dev/sdb        10475520  106088  10369432   2% /volume01
tmpfs             391084       0    391084   0% /run/user/1000
```

::: 



