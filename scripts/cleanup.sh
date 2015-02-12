#!/bin/sh -ex

emerge --nospinner cfg-update
emerge --nospinner --autounmask-write cloud-init || true
yes 1 | cfg-update -u
emerge --nospinner cloud-init
for s in config final init init-local ; do
    rc-update add cloud-$s default
done

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm -rf /var/lib/dhcp/*

#rm -rf /usr/portage

# Make sure Udev doesn't block our network
echo "cleaning up udev rules"
rm  -f /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules


sync

fstrim -v / || echo dummy



