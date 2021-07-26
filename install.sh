#!/usr/bin/env bash

set -euo pipefail

export PATH=$PWD/bin:$PATH

[[ -v INSTALL_DEVICE ]] || . prepare-env

. detect-features

partition

if [[ ${INSTALL_LUKS:-0} == 1 ]]; then
    luks-format
    luks-addkey
    luks-open
fi

lvm-create
swap-create
swap-open
btrfs-format
btrfs-mount

timedatectl set-ntp true

rsync -b --suffix=.pacnew ./rootfs/ /mnt

if [[ -v INSTALL_PACMAN_HOST ]]; then
    rsync -avz "$INSTALL_PACMAN_HOST":/var/cache/pacman/pkg/ /mnt/var/cache/pacman/pkg
fi

pacstrap-install
fstab-install
chroot-install
initrd-install
grub-install
