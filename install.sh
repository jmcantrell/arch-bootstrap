#!/usr/bin/env bash

set -euo pipefail

export PATH=$PWD/bin:$PATH

# If not using a preset, prompt the user for install details.
[[ -v INSTALL_DEVICE ]] || . prepare-env

# Set some environment variables based on this machine's capabilities.
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

# Add system file modifications, backing up the originals.
rsync -v -a --no-owner --no-group -b --suffix=.pacnew ./rootfs/ /mnt

# Try to reuse packages from another Arch Linux instance.
# TODO: Find a better way than mirroring the entire cache
if [[ -v INSTALL_PACMAN_HOST ]]; then
    mkdir -p /mnt/var/cache/pacman/pkg
    rsync -avz "$INSTALL_PACMAN_HOST":/var/cache/pacman/pkg/ /mnt/var/cache/pacman/pkg
fi

pacstrap-install
fstab-install
chroot-install
initrd-install
grub-install
