#!/usr/bin/env bash

set -euo pipefail

chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
curl https://gitlab.com/jmcantrell.keys >~/.ssh/authorized_keys

reflector --save /etc/pacman.d/mirrorlist --country US --protocol https --latest 5

pacman -Sy --noconfirm git

git clone https://gitlab.com/jmcantrell/bootstrap-arch.git ~/bootstrap

cp ~/bootstrap/rootfs/etc/systemd/network/* /etc/systemd/network
systemctl restart systemd-networkd.service
