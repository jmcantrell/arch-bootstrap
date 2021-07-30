# bootstrap-arch

My opinionated Arch Linux installer.

## Opinions

- Boot Loader: GRUB (with GPT partition table)
- Security: Optional LUKS full disk encryption
- Partition Layout: LVM (with hibernate to swap)
- File System: Btrfs (with subvolumes: `/`, `/var`, `/home`)
- Networking: networkd, resolved, nftables, iwd, Multicast DNS
- Services: ntpd, sshd, atd, plocate, pkgfile, reflector

See `packages` for installed packages.
See `rootfs` for file system modifications.

The script `rootfs/install.sh` contains additional configuration and
is removed after the installation is completed.

Any WIFI connections created during the install will be persisted to
the installed system.

## Usage

1. Boot into the Arch Linux ISO and set up networking.
1. Copy this repo to the system (e.g. `git clone` or `scp`).
1. Prepare a config file (e.g. `cp configs/sample config`).
1. Run the install script with a config file `./install.sh config`.
