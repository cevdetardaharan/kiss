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

# compression
kiss b lz4

# /var/db/kiss
curl -FLO https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.47.tar.xz
tar xvf linux-5.15.47.tar.xz
cd linux-5.15.47

# /var/db/kiss/linux-5.15.47
kiss b ncurses

# if you want perl or not || kiss b perl
patch -p1 < /usr/share/doc/kiss/wiki/kernel/no-perl.patch

# libelf
kiss b libelf
sed '/<stdlib.h>/a #include <linux/stddef.h>' tools/objtool/arch/x86/decode.c > _
mv -f _ tools/objtool/arch/x86/decode.c

# compile kernel
make && make install
mv /boot/vmlinuz /boot/vmlinuz-5.15.47
mv /boot/System.map /boot/System.map-5.15.47

# install init system
kiss b baseinit

# install efistub
kiss b efibootmgr
mount -t efivarfs none /sys/firmware/efi/efivars/
efibootmgr -c -d /dev/sda -p 1 -L "kiss" -l /vmlinuz-5.15.47 -u "root=PARTUUID={UID} console=tty1 loglevel=0 initcall_debug tsc=reliable rootfstype=ext4"

# user configuration
passwd root
adduser cennedy

# sound
kiss b alsa-utils

# gpu
kiss b mesa intel-vaapi-driver

# font
kiss b hack

# wayland
kiss b sway-tiny/wlroots foot-pgo grim slurp wl-clipboard wf-recorder wlsunset

# apps
kiss b htop pfetch mpv firefox-privacy rust neovim spotifyd transmission
