#!/usr/bin/env bash

set -euo pipefail

echo "LANG=$INSTALL_LANG" >/etc/locale.conf
sed -i -e "/#$INSTALL_LANG/s/^#//" /etc/locale.gen
locale-gen

cat >/etc/vconsole.conf <<-EOF
FONT=$INSTALL_FONT
KEYMAP=$INSTALL_KEYMAP
EOF

echo "$INSTALL_HOSTNAME" >/etc/hostname

ln -sf "/usr/share/zoneinfo/$INSTALL_TIMEZONE" /etc/localtime
hwclock --systohc --utc

echo "%wheel ALL=(ALL) ${INSTALL_SUDO_NOPASSWD:+NOPASSWD:}ALL" >/etc/sudoers.d/wheel
useradd --create-home "$INSTALL_SUDOER_USERNAME" --groups users,wheel ${INSTALL_SUDOER_SHELL:+--shell "$INSTALL_SUDOER_SHELL"}
chpasswd <<<"$INSTALL_SUDOER_USERNAME:$INSTALL_SUDOER_PASSWORD"
passwd --delete root

systemctl enable systemd-{networkd,resolved,timesyncd}.service

systemctl enable {sshd,atd,iwd,nftables}.service

systemctl enable reflector.{service,timer}

systemctl enable pkgfile-update.timer
pkgfile -u

systemctl enable fstrim.timer

gpasswd --add "$INSTALL_SUDOER_USERNAME" locate
systemctl enable plocate-updatedb.timer
updatedb

if [[ $INSTALL_VIRTUAL == oracle ]]; then
    systemctl enable vboxservice.service
    gpasswd --add "$INSTALL_SUDOER_USERNAME" vboxsf
fi
