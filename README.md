# bootstrap-arch

My opinionated Arch Linux installer.

## Opinions

- Boot Loader: GRUB (with GPT partition table)
- Security: Optional LUKS full disk encryption
- Partition Layout: LVM (with hibernate to swap)
- File System: Btrfs (with subvolumes: `/`, `/var`, `/home`)
- Networking: networkd, resolved, iwd, mDNS
- Services: sshd, timesyncd, reflector, fstrim
- Pacman Options:
  - `ParallelDownloads = 5`
  - `CleanMethod = KeepCurrent`

See `./packages` for the default package set.

See `./rootfs/` for file system modifications.

The script `./rootfs/install.sh` contains additional configuration
performed during the `chroot` step and is removed from the system
after the installation is completed.

When installing the boot loader, if EFI is detected, it will be
configured and used instead of BIOS.

Any WIFI connections created during the install will be persisted to
the installed system.

If installing in a VirtualBox virtual machine, the guest utilities
will be enabled and the privileged user will be added to the 'vboxsf'
group.

## Usage

Boot into the Arch Linux ISO and prepare the environment:

```
# Download an archive of this repo, add SSH keys, and enable mDNS (archiso.local).
curl -s https://gitlab.com/jmcantrell/bootstrap-arch/-/raw/master/init.sh | bash -s

# Create a config file and edit it to suit your installation.
cp ./configs/sample config

# Set environment variables necessary for installation.
. ./prepare.sh ./config

# Optionally, add some extra packages to install.
echo zsh >>packages

# Start an unattended installation.
./install.sh
```

After installation, the system is left mounted at `/mnt`.
