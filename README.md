# bootstrap-arch

My opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the
resulting system closely matches what you would get from following the
[official installation guide][1].

## Opinions

- Boot loader: GRUB (with GPT partition table)
- Security: Optional LUKS full disk encryption
- Partition layout: LVM (with hibernate to swap)

Default btrfs subvolumes:

- `/`
- `/home`
- `/var/log`

Services:

- networkd (mDNS enabled)
- resolved
- iwd
- sshd
- timesyncd
- reflector
- fstrim

Pacman options:

- `ParallelDownloads = 5`
- `CleanMethod = KeepCurrent`

Blacklisted kernel modules:

- `pcspkr`

## Configuration

The installation environment is defined in `./config/environment`. It
illustrates the recognized environment variables with some default
values. Every uncommented line in this file is a required variable.

The file system subvolumes are defined in `./config/subvolumes`. Every
line must be of the form `@name /path/to/subvolume`.

The packages to be installed are defined in `./config/packages`.
Packages can be added, but if any are removed, the installation will
probably fail.

File system tree modifications are defined in `./rootfs/`. This
directory will be `rsync`ed to `/` with the permissions (but not
ownership) intact.

The script `./rootfs/install.sh` contains additional configuration
performed during the `chroot` step and is removed from the resulting
system after the installation is completed.

## Behavior

When installing the boot loader, if EFI is detected, it will be
configured and used instead of BIOS.

Any wireless connections created during the install will be persisted
to the installed system.

If installing in a VirtualBox virtual machine, the guest utilities
will be enabled and the privileged user will be added to the `vboxsf`
group.

## Usage

Boot into the Arch Linux ISO and prepare the environment:

```sh
# Optionally, connect to a wireless access point.
iwctl station wlan0 connect <ssid>

# Download an archive of this repo, add SSH keys, and enable mDNS (archiso.local).
curl -s https://gitlab.com/jmcantrell/bootstrap-arch/-/raw/master/init.sh | bash -s

# Optionally, add some extra packages to install.
echo zsh >>./config/packages

# Optionally, change the btrfs subvolumes.
vim ./config/subvolumes

# Edit the environment file to suit your needs.
vim ./config/environment

# Prepare the installation environment.
. ./prepare.sh

# Start an unattended installation.
./install.sh
```

After installation, the system is left mounted at `/mnt`.

If all is well, `poweroff`.

[1]: https://wiki.archlinux.org/title/Installation_guide
