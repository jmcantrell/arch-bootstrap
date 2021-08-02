#!/usr/bin/env bash

set -euo pipefail

localize

partition

if [[ -v INSTALL_LUKS_DEVICE ]]; then
    luks-format
    luks-addkey
    luks-open
fi

lvm-create

swap-create
swap-open

fs-format
fs-mount

pacstrap-install
fstab-install
chroot-install
initrd-install
grub-install
