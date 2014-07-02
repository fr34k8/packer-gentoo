#!/bin/sh -ex

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm -rf /var/lib/dhcp/*

rm -rf /usr/portage

# Make sure Udev doesn't block our network
echo "cleaning up udev rules"
rm  -f /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules

# Zero out the free space to save space in the final image:
echo "Zeroing device to make space..."

fstrim -v / || echo dummy
dd if=/dev/zero of=/EMPTY bs=1M || echo dummy
rm -f /EMPTY

sync


