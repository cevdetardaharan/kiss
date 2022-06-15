# create partitions
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# mount partitions
mount /dev/sda2 /mnt
mount /dev/sda1 /mnt/boot

# tarball
ver=2021.7-9
url=https://github.com/kisslinux/repo/releases/download/$ver
file=kiss-chroot-$ver.tar.xz

# install tarball
curl -fLO "$url/$file"

# extract tarball
cd /mnt
tar xvf "$OLDPWD/$file"

# chroot
genfstab /mnt >> /mnt/etc/fstab
/mnt/bin/kiss-chroot /mnt

# /var/db/kiss
git clone https://github.com/kiss-community/repo.git

# /etc/profile.d/kiss_path.sh
export KISS_PATH=''                       
KISS_PATH=$KISS_PATH:/var/db/kiss/repo/core
KISS_PATH=$KISS_PATH:/var/db/kiss/repo/extra
KISS_PATH=$KISS_PATH:/var/db/kiss/repo/wayland
export CFLAGS="-O3 -pipe -march=native"
export CXXFLAGS="$CFLAGS"
export MAKEFLAGS="-j4"

# reload /etc/profile.d/kiss_path.sh
. /etc/profile.d/kiss_path.sh

# update system
kiss update
cd /var/db/kiss/installed && kiss build *

# install filesystem utilities
kiss b e2fsprogs
kiss b dosfstools

# install efistub
kiss b efibootmgr
mount -t efivarfs none /sys/firmware/efi/efivars/
efibootmgr -c -d /dev/sda -p 1 -L "kiss" -l /vmlinuz-5.15.46-gnu -u "root=PARTUUID={UID} console=tty1 loglevel=0 initcall_debug tsc=reliable rootfstype=ext4"
