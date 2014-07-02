#!/bin/bash -xe

ntpdate ntp.se &

fdisk /dev/sda <<EOF
o
n
p
1
2048

a
1
w
EOF

# Format partitions created in the boot_command
mkfs.ext4 /dev/sda1


# Mount other partitions
mount -t ext4 -o rw,relatime,discard /dev/sda1 /mnt/gentoo

FILE=$(wget -q http://mirror.yandex.ru/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64/ -O - | grep -o -e "stage3-amd64-\w*.tar.bz2" | uniq)
[ -z "$FILE" ] && exit 1
wget http://mirror.yandex.ru/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64/$FILE -O /mnt/gentoo/stage.tar.bz2 || exit 1
tar -C /mnt/gentoo -jxpf /mnt/gentoo/stage.tar.bz2
rm -f /mnt/gentoo/stage.tar.bz2
wget http://mirror.yandex.ru/gentoo-distfiles/snapshots/portage-latest.tar.bz2 -O /mnt/gentoo/portage.tar.bz2
tar -C /mnt/gentoo/usr/ -jxf /mnt/gentoo/portage.tar.bz2
rm -f /mnt/gentoo/portage.tar.bz2
sync

cp -L /etc/resolv.conf /mnt/gentoo/etc/

echo hostname="build" > /mnt/gentoo/etc/conf.d/hostname
echo -e "
/dev/sda1    /           ext4        defaults,discard,relatime         0 1
none         /var/tmp    tmpfs       size=4G,nr_inodes=1M     0 0

" >> /mnt/gentoo/etc/fstab

sed -i '/\/dev\/BOOT.*/d' /mnt/gentoo/etc/fstab
sed -i '/\/dev\/ROOT.*/d' /mnt/gentoo/etc/fstab
sed -i '/\/dev\/SWAP.*/d' /mnt/gentoo/etc/fstab

mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev

cat <<EOF >> /mnt/gentoo/etc/portage/package.keywords
sys-kernel/dracut ~amd64 amd64
EOF

MAKECONF=/mnt/gentoo/etc/portage/make.conf
[ ! -f $MAKECONF ] && [ -f /mnt/gentoo/etc/make.conf ] && MAKECONF=/mnt/gentoo/etc/make.conf
echo $MAKECONF

cat <<DATAEOF >> $MAKECONF
MAKEOPTS="-j2"
GENTOO_MIRRORS="http://mirror.yandex.ru/gentoo-distfiles/"
SYNC="http://mirror.yandex.ru/gentoo-portage/"
FEATURES="\${FEATURES} parallel-fetch"
USE="${USE} -X -bindist idn iproute2"
CFLAGS="-mtune=generic -O2 -pipe"
CXXFLAGS="\${CFLAGS}"
LINGUAS=""
DRACUT_MODULES="qemu qemu-net"
DATAEOF

echo "keymap=\"sv-latin1\"" >> /mnt/gentoo/etc/conf.d/keymaps
echo "LANG=\"en_US.UTF-8\"" > /mnt/gentoo/etc/env.d/02locale
echo "rc_logger=\"YES\"" >> /mnt/gentoo/etc/rc.conf
echo "rc_sys=\"\"" >> /mnt/gentoo/etc/rc.conf

wget $(cat /tmp/host)/config-3.12.21 -O /mnt/gentoo/tmp/config-3.12.21
chroot /mnt/gentoo /bin/bash -ex<<DATAEOF

echo UTC > /etc/timezone
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
source /etc/profile
env-update
ln -sf /proc/self/mounts /etc/mtab
echo 'config_eth0=( "dhcp" )' >> /etc/conf.d/net
ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
rc-update add net.eth0 default

ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
echo SYNC=\"rsync://mirror.yandex.ru/gentoo-portage/\" >> /etc/portage/make.conf

echo "updating Portage Tree..."
emerge --sync --quiet



emerge --nospinner  grub
sed -i 's/^#\s*GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="net.ifnames=0"/' /etc/default/grub
grub2-install /dev/sda

emerge --nospinner sys-kernel/gentoo-sources dracut openssh
rc-update add sshd default
cd /usr/src/linux
mv /tmp/config-3.12.21 .config
make olddefconfig

make all modules_install install
dracut -H -k \$(ls /lib/modules) -f
make clean

grub2-mkconfig -o /boot/grub/grub.cfg

echo root:build | chpasswd
DATAEOF

reboot
sleep 50

