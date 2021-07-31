#!/usr/bin/env bash

set -euo pipefail

export PATH=$PWD/bin:$PATH

timedatectl set-ntp true

partition

if [[ -v INSTALL_LUKS_DEVICE ]]; then
    luks-format
    luks-addkey
    luks-open
fi

lvm-create

swap-create
swap-open

btrfs-format
btrfs-mount

pacstrap-install
fstab-install
chroot-install
initrd-install
grub-install
