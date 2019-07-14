#! /bin/sh
# things we can do inside a chroot

apk update
apk add curl busybox btrfs-progs wget htop iproute2 openssh cryptsetup util-linux wget parted bash  sudo tar tmux vim

cd /etc/ssh
ssh-keygen -A

#--- prepare 1st boot image
cpAllBinaries () {
  BIN=$1
	LIBS=$(ldd $BIN | sed -e 's/.* =>//' -e 's/\( \/.\)/\1/' -e 's/(.*)//')
	cp -Lv --parents $BIN $ROOTFS/
	cp -Lv --parents $LIBS $ROOTFS/
}

ROOTFS=/mnt
cpAllBinaries `which mkfs.btrfs`
cpAllBinaries `which cryptsetup`
cpAllBinaries `which btrfs`
cpAllBinaries `which blkid`
cpAllBinaries `which lsblk`
cpAllBinaries `which parted`
cpAllBinaries `which partprobe`
cpAllBinaries `which wget`
cpAllBinaries `which curl`
cpAllBinaries `which bash`
cpAllBinaries `which busybox`
cpAllBinaries `which switch_root`
#following ar busybox applets
BUSYBOXAPP="blkid blockdev chroot depmod fdisk findfs fsck fstrim getty halt hdparm hwclock init ip loadkmap lsmod mdev mkdosfs mkfs.vfat modinfo modprobe reboot route setconsole slattach sysctl tar"
for ba in $BUSYBOXAPP; do 
  cd $ROOTFS/sbin/
  ln -s /bin/busybox $ba
done
BUSYBOXAPP="cat chgrp chmod chown cp cpio date dd df dmesg echo false fdflush fgrep grep gunzip gzip hostname iostat kbd_mode kill ln ls lzop mkdir mknode mktemp more mount mountpoint mv netstat ping ping6 ps pwd rm rmdir sed setpriv sh sleep sync tar touch true uname zcat"
for ba in $BUSYBOXAPP; do 
  cd $ROOTFS/bin/
  ln -s busybox $ba
done
