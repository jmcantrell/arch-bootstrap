# bootstrap-arch

My mildly-opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the
resulting system closely matches what you would get from following the
[official installation guide][install].

## Opinions

Boot loading is handled by [GRUB][grub] with a [GPT][gpt] partition
table using BIOS or [UEFI][uefi] mode, depending on the detected
hardware capabilities.

Logical volume management is handled by [LVM][lvm], including a
logical volume for swap (allowing for hibernation).

If enabled, full disk encryption is handled by [LUKS][luks], using the
[LVM on LUKS][lvm-on-luks] method.

The file system is formatted using [Btrfs][btrfs] (with
[subvolumes][btrfs-subvols]).

[Processor microcode updates][microcode] will be installed according
to the system's CPU vendor (Intel or AMD).

[Early KMS start][early-kms-start] is enabled for any detected
graphics drivers (i.e. if the output of `lspci -k` shows a kernel
module for your device).

The following services are installed and enabled:

- [fstrim][ssd] (if installation disk is SSD)
- [iwd] (if wireless devices are present)
- [systemd-networkd]
- [systemd-resolved]
- [systemd-timesyncd]
- [reflector]
- [sshd]

Any wireless connections created during the install will be persisted
to the installed system.

A privileged user will be created and the root account will be
disabled.

## Usage

In general, the installation steps are as follows:

1. Boot into the [Arch Linux ISO][archiso]
1. Change the directory to this repository
1. Prepare the environment: `source ./scripts/prepare`
1. Run the installation script: `./scripts/install`

After installation, the system is left mounted for inspection.

If all is well, `poweroff` and eject the installation media.

## Configuration

The resulting system is described by a configuration directory. The
default configuration directory at `./config` is what I consider a
reasonable starting point based on the opinions outlined above.

The details of a _particular_ system are controlled entirely by
environment variables. The only explicitly required variable is
`INSTALL_DEVICE` (e.g. `/dev/sda`). Look through the preparation
script to see the other variables and their default values.

To begin a new installation, the environment must be populated by
sourcing the preparation script `./scripts/prepare`. By default, this
script will look at the default configuration directory, but an
alternate one can be used by passing it as the first argument.

To prepare the default configuration:

```sh
source ./scripts/prepare
```

To prepare an alternate configuration:

```sh
source ./scripts/prepare /path/to/another/config
```

If the script succeeds, a list of all the relevant environment
variables and their values will be displayed as a sanity check (with
sensitive information hidden).

Within a configuration directory, the following files are recognized:

### `subvolumes`

This file, if it exists, defines the extra [btrfs
subvolumes][btrfs-subvols] that will be created.

If it's executable, it should output one subvolume mapping per line to
stdout. If it's a regular file, it should contain one subvolume
mapping per line.

Every line must be of the form:

```
name /path/to/subvolume
```

The root subvolume should not be included, as it is not optional. It
will always be created and mounted at `/` (`INSTALL_DIR` or
`/mnt/install` during installation).

### `packages`

This file, if it exists, defines the extra packages that will be
installed on the new system.

If it's executable, it should output one package per line to stdout.
If it's a regular file, it should contain one package per line.

Aside from these extra packages, only the packages necessary for a
functional system will be installed.

### `install`

This script, if it exists and is executable, will be run in a chroot
just after packages have been installed.

### `templates/*`

This directory tree contains files necessary for installation, but
with potentially varying details.

### `files/*`

This directory tree, if it exists, contains files that will be added
unchanged to the installation. It will be `rsync`ed to `/` with the
permissions (but not ownership) intact.

## Installation

After the preparation script is sourced, the only other necessary step
is to run the installation script:

```sh
./scripts/install
```

This script is intentionally kept extremely simple and easy to read.
It serves as a good overview of the installation process. As `./bin`
is now in `PATH`, feel free to execute each step separately to verify
they're working as intended.

The commands can also be useful outside of the context of
installation. For example, the following can be used to mount an
existing system (provided the configuration directory and environment
match):

```sh
source ./scripts/prepare
luks-open
swap-open
fs-mount
arch-chroot "$INSTALL_DIR"
```

### Initialize the SSH server and enable mDNS

If you want or need to manage the installation over SSH, the
`./scripts/init` script can make this easier. It does the following:

- Authorizes the SSH keys with write access to this repository
- Enables [Multicast DNS][mdns], making `archiso.local` reachable
- Fetches a tarball of this repository into `/root` (if necessary)

If you already have access to the repository in the live environment,
just run it:

```
./scripts/init
```

If you need to download the repository too, just `curl` it:

```
curl https://github.com/jmcantrell/bootstrap-arch/archive/refs/heads/main.zip | bash -s
```

If you don't need to manually connect to the internet, you could also
run the script by using the `script` boot parameter, recognized by the
Arch Linux ISO.

When you see the GRUB menu as the live environment is booting, press
the `<tab>` key to edit the kernel command line and add the following:

```
script=https://github.com/jmcantrell/bootstrap-arch/raw/main/scripts/init
```

The script will be run similarly to the curl method above as soon as
the environment is ready.

[archiso]: https://archlinux.org/download/
[btrfs-subvols]: https://wiki.archlinux.org/title/Btrfs#Subvolumes
[btrfs]: https://wiki.archlinux.org/title/Btrfs
[early-kms-start]: https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start
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
