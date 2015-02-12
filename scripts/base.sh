#!/bin/sh -ex

emerge --nospinner cfg-update
emerge --nospinner --autounmask-write dracut || true
yes 1 | cfg-update -u

emerge --nospinner dracut

dracut -H -f /boot/initramfs-$(uname -r).img
grub2-mkconfig -o /boot/grub/grub.cfg
