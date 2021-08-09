#!/usr/bin/env bash

set -euo pipefail

cd ~

if [[ ! -d bootstrap-arch-master ]]; then
    # If running this script from the output of curl, then get the rest of the repo.
    curl -sLO https://gitlab.com/jmcantrell/-/archive/master/bootstrap-arch-master.tar.gz
    tar -v -x -f bootstrap-arch-master.tar.gz
    cd bootstrap-arch-master
fi

mkdir -p ~/.ssh
chmod 700 ~/.ssh
curl -sL https://gitlab.com/jmcantrell.keys >~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

cp ./rootfs/etc/systemd/network/* /etc/systemd/network
systemctl restart systemd-networkd.service
