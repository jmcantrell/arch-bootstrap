# bootstrap-arch

My opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the
resulting system closely matches what you would get from following the
[official installation guide][1].

## Opinions

Boot loading is handled by GRUB with a GPT partition table using BIOS
or EFI mode, depending on the hardware capabilities.

Logical volume management is handled by LVM, including a swap
partition (allowing for hibernation). If enabled, full disk encryption
is handled by LUKS, using the [LVM on LUKS][2] method.

The file system is formatted with btrfs using the [suggested subvolume
layout][3] (configurable).

The following services are installed and enabled:

- [networkd][4]
- [resolved][5] ([mDNS enabled][6])
- [iwd][7]
- [sshd][8]
- [timesyncd][9]
- [reflector][10]
- [fstrim][11]

The following pacman options are changed:

- `ParallelDownloads = 5`
- `CleanMethod = KeepCurrent`

The following kernel modules are blacklisted:

- `pcspkr`

Any wireless connections created during the install will be persisted
to the installed system.

If [installing as a VirtualBox guest][12], the guest utilities will be
enabled and the privileged user will be added to the `vboxsf` group.

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

## Usage

Boot into the Arch Linux ISO and prepare the environment:

```sh
# Optionally, connect to a wireless access point.
iwctl station wlan0 connect <ssid>

# Download an archive of this repo, add SSH keys, and enable mDNS (archiso.local).
curl -s https://gitlab.com/jmcantrell/bootstrap-arch/-/raw/master/init.sh | bash -s

cd ~/bootstrap-arch-master

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
[2]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[3]: https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout
[4]: https://wiki.archlinux.org/title/Systemd-networkd
[5]: https://wiki.archlinux.org/title/Systemd-resolved
[6]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[7]: https://wiki.archlinux.org/title/Iwd
[8]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[9]: https://wiki.archlinux.org/title/Systemd-timesyncd
[10]: https://wiki.archlinux.org/title/Reflector
[11]: https://wiki.archlinux.org/title/Solid_state_drive
[12]: https://wiki.archlinux.org/title/VirtualBox/Install_Arch_Linux_as_a_guest
