#!/bin/sh -ex

emerge --nospinner cfg-update
yes 1 | cfg-update -u

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm -rf /var/lib/dhcp/*

#rm -rf /usr/portage

# Make sure Udev doesn't block our network
echo "cleaning up udev rules"
rm  -f /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules

rm -rf /usr/portage/
cat <<EOF > /etc/local.d/portage.start
#/bin/bash
rm -f /etc/local.d/portage.start
wget http://mirror.yandex.ru/gentoo-distfiles/snapshots/portage-latest.tar.bz2 -O /portage.tar.bz2
tar -C /usr/ -jxf /portage.tar.bz2
rm -f /portage.tar.bz2
EOF
chmod +x /etc/local.d/portage.start
sync
rc-update add local default

fstrim -v / || echo dummy



