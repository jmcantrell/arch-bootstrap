#!/usr/bin/env bash

set -euo pipefail

echo "LANG=$INSTALL_LANG" >/etc/locale.conf

sed -i -e "/#$INSTALL_LANG/s/^#//" /etc/locale.gen
locale-gen

echo "KEYMAP=$INSTALL_KEYMAP" >/etc/vconsole.conf

echo "$INSTALL_HOSTNAME" >/etc/hostname

ln -sf "/usr/share/zoneinfo/$INSTALL_TIMEZONE" /etc/localtime
hwclock --systohc --utc

echo "%wheel ALL=(ALL) ${INSTALL_SUDOER_NOPASSWD:+NOPASSWD:}ALL" >/etc/sudoers.d/wheel

useradd --create-home "$INSTALL_SUDOER_USERNAME" --groups users,wheel --shell /bin/zsh
chpasswd <<<"$INSTALL_SUDOER_USERNAME:$INSTALL_SUDOER_PASSWORD"
passwd --delete root

systemctl enable ntpd.service

systemctl enable sshd.service

systemctl enable systemd-{networkd,resolved}.service

systemctl enable nftables.service

systemctl enable reflector.{service,timer}

systemctl enable pkgfile-update.timer

systemctl enable atd.service

systemctl enable iwd.service

gpasswd --add "$INSTALL_SUDOER_USERNAME" locate
systemctl enable plocate-updatedb.timer

if [[ ${INSTALL_VIRTUALBOX:-0} == 1 ]]; then
    pacman -S --noconfirm --needed virtualbox-guest-utils-nox
    systemctl enable vboxservice.service
    gpasswd --add "$INSTALL_SUDOER_USERNAME" vboxsf
fi
