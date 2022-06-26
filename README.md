# bootstrap-arch

My opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the
resulting system closely matches what you would get from following the
[official installation guide][install].

## Opinions

Boot loading is handled by [GRUB][grub] with a [GPT][gpt] partition
table using BIOS or [UEFI][uefi] mode, depending on the detected
hardware capabilities.

Logical volume management is handled by [LVM][lvm], including a swap
partition (allowing for hibernation).

If enabled, full disk encryption is handled by [LUKS][luks], using the
[LVM on LUKS][lvm-on-luks] method.

The file system is formatted using [Btrfs][btrfs] (with
[subvolumes][btrfs-subvols]).

[Processor microcode updates][microcode] will be installed according
to the system's CPU vendor (Intel or AMD).

The following services are installed and enabled:

- [fstrim][ssd] (if installation disk is SSD)
- [iwd] (if wireless devices are present)
- [systemd-networkd]
- [systemd-resolved] (with [mDNS][mdns] enabled)
- [systemd-timesyncd]
- [reflector]
- [sshd]

The following changes are made to `/etc/pacman.conf`:

- `ParallelDownloads = 5`
- `CleanMethod = KeepCurrent`

The following kernel modules are blacklisted:

- `pcspkr`

Any wireless connections created during the install will be persisted
to the installed system.

## Configuration

Details of the installation can be controlled from the default
configuration at `./config`. This directory can be used as a template
if multiple preset configurations are needed.

The preparation script will, by default, use this directory, but it
can be overridden by passing another directory as the first argument:

```sh
. ./scripts/prepare /path/to/another/config
```

Within a configuration directory, the following files are recognized:

### `environment`

This file will be used by `./scripts/prepare` to initialize the
environment variables needed for installation. Look through that
script to see the default values and other variables that can be
overridden.

The only required variables are:

- `INSTALL_DEVICE` (e.g. `/dev/sda`)
- `INSTALL_SWAP_SIZE` (e.g. `4G`)
- `INSTALL_HOSTNAME`
- `INSTALL_SUDOER_USERNAME`
- `INSTALL_SUDOER_PASSWORD`

### `subvolumes`

This file defines the [btrfs subvolumes][btrfs-subvols] that will be
created. Every line must be of the form:

```
@name /path/to/subvolume
```

At the very least, this file must contain the root subvolume (it must
be the first line in the file).

### `packages`

This script defines the packages that will be installed on the new
system. It should output a list of packages to stdout, one per line.

### `install`

This script, if it exists and is executable, will be run in a chroot
just after packages have been installed.

### `templates/*`

This directory tree contains files necessary for installation, but
with potentially varying details.

### `files/*`

This directory tree, if it exists, contains static content that will
be added to the installation. It will be `rsync`ed to `/` with the
permissions (but not ownership) intact.

## Usage

In general, the installation steps are as follows:

1. Boot into a copy of the [Arch Linux ISO][archiso]
1. Connect to the internet, if needed
1. Copy this repository to the live environment
1. Change the directory to this repository
1. Customize the configuration (e.g. `./config` or some derivative)
1. Prepare the environment: `. ./scripts/prepare [/path/to/config/dir]`
1. Run the installation script: `./scripts/install`

After installation, the system is left mounted for inspection.

If all is well, `poweroff` and eject the ISO.

### Initialize the SSH server and enable mDNS

If you want or need to manage the installation over SSH, the
`./scripts/init` script can make this easier. It does the following:

- Gets a copy of this repository, if needed
- Authorizes the SSH keys with access to this repository
- Enables [Multicast DNS][mdns], making `archiso.local` reachable

If you already have the repository copied to the live environment,
just run it:

```
./scripts/init
```

If you need to download the repository too, just `curl` it:

```
curl https://gitlab.com/jmcantrell/bootstrap-arch/-/raw/main/scripts/init | bash -s
```

If you don't need to manually connect to the internet, you could also
run the script by using the `script` boot parameter, recognized by the
Arch Linux ISO.

When you see the GRUB menu as the live environment is booting, press
the `<tab>` key to edit the kernel command line and add the following:

```
script=https://gitlab.com/jmcantrell/bootstrap-arch/-/raw/main/scripts/init
```

The script will be run similarly to the curl method above as soon as
the environment is ready.

[archiso]: https://archlinux.org/download/
[btrfs-subvols]: https://wiki.archlinux.org/title/Btrfs#Subvolumes
[btrfs]: https://wiki.archlinux.org/title/Btrfs
[gpt]: https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
[grub]: https://wiki.archlinux.org/title/GRUB
[install]: https://wiki.archlinux.org/title/Installation_guide
[iwd]: https://wiki.archlinux.org/title/Iwd
[luks]: https://wiki.archlinux.org/title/Dm-crypt
[lvm-on-luks]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[lvm]: https://wiki.archlinux.org/title/LVM
[mdns]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[microcode]: https://wiki.archlinux.org/title/Microcode
[reflector]: https://wiki.archlinux.org/title/Reflector
[ssd]: https://wiki.archlinux.org/title/Solid_state_drive
[sshd]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[systemd-networkd]: https://wiki.archlinux.org/title/Systemd-networkd
[systemd-resolved]: https://wiki.archlinux.org/title/Systemd-resolved
[systemd-timesyncd]: https://wiki.archlinux.org/title/Systemd-timesyncd
[uefi]: https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface
