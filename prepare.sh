#!/usr/bin/env bash

config=$1

if [[ -z $config ]]; then
    echo "missing config file" >&2
    exit 1
fi

if [[ ! -r $config ]]; then
    echo "config file missing or not readable" >&2
    exit 1
fi

if ! . "$config"; then
    echo "unable to source config file" >&2
    exit 1
fi

export PATH=$PWD/bin:$PATH

export INSTALL_GRUB_DEVICE=${INSTALL_DEVICE}1
export INSTALL_OS_DEVICE=${INSTALL_DEVICE}2

if [[ -v INSTALL_LUKS_PASSPHRASE ]]; then
    export INSTALL_LUKS_DEVICE=$INSTALL_OS_DEVICE
    export INSTALL_LUKS_NAME=crypt
    export INSTALL_LUKS_MAPPER=/dev/mapper/$INSTALL_LUKS_NAME
    export INSTALL_LUKS_KEYFILE=$PWD/keyfile-$INSTALL_LUKS_NAME.bin
    export INSTALL_LVM_DEVICE=$INSTALL_LUKS_MAPPER
else
    export INSTALL_LVM_DEVICE=$INSTALL_OS_DEVICE
fi

export INSTALL_ROOT_DEVICE=/dev/mapper/vg-root
export INSTALL_SWAP_DEVICE=/dev/mapper/vg-swap

case $(grep -w -m1 '^vendor_id' /proc/cpuinfo | awk '{print $NF}') in
GenuineIntel) export INSTALL_CPU_VENDOR=intel ;;
AuthenticAMD) export INSTALL_CPU_VENDOR=amd ;;
esac

if systemd-detect-virt | grep -wq oracle; then
    export INSTALL_VIRTUALBOX=1
fi

if [[ ! -v INSTALL_LANG ]]; then
    [[ ! -v LANG && -r /etc/locale.conf ]] && . /etc/locale.conf
    export INSTALL_LANG=${LANG:-en_US.UTF-8}
fi

if [[ ! -v INSTALL_KEYMAP ]]; then
    [[ ! -v KEYMAP && -r /etc/vconsole.conf ]] && . /etc/vconsole.conf
    export INSTALL_KEYMAP=${KEYMAP:-us}
fi

if [[ ! -v INSTALL_FONT ]]; then
    [[ ! -v FONT && -r /etc/vconsole.conf ]] && . /etc/vconsole.conf
    export INSTALL_FONT=${FONT:-Lat2-Terminus16}
fi

if [[ ! -v INSTALL_TIMEZONE ]]; then
    if [[ -r /etc/localtime ]]; then
        INSTALL_TIMEZONE=$(realpath /etc/localtime)
        INSTALL_TIMEZONE=${INSTALL_TIMEZONE#/usr/share/zoneinfo/}
    else
        INSTALL_TIMEZONE=UTC
    fi
    export INSTALL_TIMEZONE
fi
