# bootstrap-arch

My opinionated scripts for installing and configuring Arch Linux.

## Opinions

- GPT partition table
- GRUB boot loader
- Optional LUKS full disk encryption (including swap)
- LVM volume management
- BTRFS file system with subvolumes (`/`, `/var`, `/home`)

## Usage

1. Boot into the Arch Linux ISO and set up networking.
1. Get the files to the system somehow (e.g. `git clone` or `scp`).
1. Optionally, source a preconfigured install in `./presets`.
1. Run the install script `./install.sh`.
