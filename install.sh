#!/usr/bin/env bash

set -euo pipefail

export PATH=$PWD/bin:$PATH

config=${1-}

if [[ -z $config ]]; then
    echo "no config file provided" >&2
    exit 1
fi

if [[ ! -r $config ]]; then
    echo "config file not found" >&2
    exit 1
fi

timedatectl set-ntp true

. "$config"
. prepare

partition

if [[ -v INSTALL_LUKS_PASSPHRASE ]]; then
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
