#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
curl https://gitlab.com/jmcantrell.keys >~/.ssh/authorized_keys

cd ~

archive_name=bootstrap-arch-master
curl -O https://gitlab.com/jmcantrell/bootstrap-arch/-/archive/master/"$archive_name".tar.gz
tar -x -f "$archive_name".tar.gz

cd ~/"archive_name"

cp ./rootfs/etc/systemd/network/* /etc/systemd/network
systemctl restart systemd-networkd.service
