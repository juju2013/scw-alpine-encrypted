Alpine linux for scaleway
=========================

[Scaleway](https://www.scaleway.com) does not provide [alpine Linux](https://alpinelinux.org/) images to their ARM instances, neither for cloud kvm nor bare-metal instances.

This is a shell script to deploy an alpine Linux with encrypted file-system to them.

## Singularities:

 * Target ARM, both armv7 and aarch64
 * Boot over your own HTTP server
 * Encrypted root file-system with interactif passphrase prompt to unlock
 * Btrfs for fun

## Prerequisites:

 * A working linux system with chroot capability
  * Same arch as target, known as `build machine`
 * A http server, known as `boot server`
 * [scw-cli](https://github.com/scaleway/scaleway-cli)
 * Scaleway's public infrastructure
 * That's all
 
## Usage:

### On `build machine`
Checkout this repo:
```bash
git clone https://github.com/juju2013/scw-alpine-encrypted
cd scw-alpine-encrypted
```
 * Check build.sh and adapte it to your needs
 * Copy your own ssh public key(s), ending with .pub, to keys/
 * run ```./build.sh```

That's all. In out/ folder, there'll be 2 files:

 * ${ARCH}init.tar - your initrd. You''ll need this one every time your target system boots
 * ${ARCH}root.tar - your root file-system, you'll need it only for the first installation

### On `boot server`
 * Copy those init.tar and root.tar to somewhere you can wget
 
### On the target
 * Goto your [console](https://console.scaleway.com), select your target and add following tags:
 
```
boot=rescue rescue_image=http://your_boot_server/path_to_your_init.tar
```

Fire up (or reset) your instance and connect to it's console:
```
scw attach your_instance
```

When the boot is finished, you'll reach some point like that:
```
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
vda     253:0    0 46.6G  0 disk 
├─vda1  253:1    0 46.5G  0 part 
└─vda15 253:15   0  100M  0 part 
mount: mounting /dev/mapper/cryptroot on /mnt failed: No such file or directory
Filesystem           1K-blocks      Used Available Use% Mounted on
udev                   1015648         0   1015648   0% /dev
tmpfs                   204048     10140    193908   5% /run
none                   1020228    202340    817888  20% /
bash: cannot set terminal process group (-1): Not a tty
bash: no job control in this shell
bash-5.0# 
```

From there (you'll lose all your data on /dev/vda1), enter commands after `bash-5.0#`, the orther lines are command output:
```
bash-5.0# cryptsetup luksFormat /dev/vda1
WARNING: Device /dev/vda1 already contains a 'ext4' superblock signature.

WARNING!
========
This will overwrite data on /dev/vda1 irrevocably.

Are you sure? (Type uppercase yes): YES
Enter passphrase for /dev/vda1: 
Verify passphrase: 
[  193.092325] NET: Registered protocol family 38
[  193.158943] cryptd: max_cpu_qlen set to 1000
```
Then
```
cryptsetup open /dev/vda1 cryptroot
Enter passphrase for /dev/vda1: 
bash-5.0# mkfs.btrfs /dev/mapper/cryptroot 
...
bash-5.0# mount /dev/mapper/cryptroot /mnt/
bash-5.0# btrfs sub create /mnt/root
Create subvolume '/mnt/root'
bash-5.0# cd /mnt/root
bash-5.0# wget -O - http://your_boot_server/aarch64root.tar | tar xpf -
bash-5.0# mount --bind /dev dev
bash-5.0# mount --bind /sys sys
bash-5.0# mount --bind /proc proc
bash-5.0# chroot . /bin/bash
```
At this point, you're going to setup your alpine Linux system. Customize it as you want(most defaults should be ok):
```
setup-alpine
```
After the setup:
```
bash-5.0# exit
exit
bash-5.0# exit
exit
Now switching to real root
switch_root: cannot access /sbin/init: No such file or directory
switch_root: failed to execute /sbin/init: No such file or directory
```
The new system will panic, that's OK, simply reboot it throu the console.

After a while, your console will show:
```
[   27.400885] random: crng init done
Loading kernel modules ...
modprobe: module dm-mod not found in modules.dep
[   48.390779] xor: measuring software checksum speed
...
Starting mount real root device:
WARNING: Locking directory /run/cryptsetup is missing!
Enter passphrase for /dev/vda1: 
```
Enter your passphrase, and you'll see:
```
[  115.616635] NET: Registered protocol family 38
[  115.681441] cryptd: max_cpu_qlen set to 1000
NAME          MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
vda           253:0    0 46.6G  0 disk  
├─vda1        253:1    0 46.5G  0 part  
│ └─cryptroot 252:0    0 46.5G  0 crypt 
└─vda15       253:15   0  100M  0 part  
[  116.031438] BTRFS: device fsid f2fbe983-e033-494c-83cd-72e81b519c1f devid 1 transid 16 /dev/mapper/cryptroot
[  116.041778] BTRFS info (device dm-0): disk space caching is enabled
[  116.046932] BTRFS info (device dm-0): has skinny extents
Filesystem           1K-blocks      Used Available Use% Mounted on
udev                   1015648         0   1015648   0% /dev
tmpfs                   204048     10140    193908   5% /run
none                   1020228    202340    817888  20% /
/dev/mapper/cryptroot
                      48708300     88288  48106176   0% /mnt
bash: cannot set terminal process group (-1): Not a tty
bash: no job control in this shell
```
Type simply ```exit```, then you'll see:
```
exit
Now switching to real root

   OpenRC 0.41.2.6fc2696f3e is starting up Linux 4.19.53-mainline-rev1 (aarch64)
...
```
That's all.

You can now ```ssh root@your_instance_ip```. And next boots will repeat the same sequence, it's done!

## Caveats:

 * HTTP only, no https. The first wget is from busybox and it seams too complicate to require SSL at the very first stage. Also migitated by the third point.
 * No swap with btrfs. If you realy want one, allocate another 50GB SSD (it costs 1€/month) and make your swap partition there. You can 
[allocate](https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices) the remaining space to your /, after having cryptsetup it.
 * Encryption is not bullet proof. Scaleway owns your kernel and first initrd. It's not the right way to prevent any 3 letters agencies, not even your cloud provider's
 employees to access your data. (But it does prevent most leaks by the eventual fault of any sub-contractors).
 
