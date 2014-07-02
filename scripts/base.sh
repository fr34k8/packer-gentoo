#!/bin/sh -ex

emerge sync
emerge gentoolkit
emerge --update --deep --with-bdeps=y --newuse @world
emerge --depclean
revdep-rebuild
grub-mkconfig -o /boot/grub/grub.cfg
