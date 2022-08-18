# bootstrap-arch

A mildly-opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the resulting system closely matches what you would get from following the [official installation guide][guide].

## Opinions

Boot loading is handled by [GRUB][grub] with a [GPT][gpt] partition table using BIOS or [UEFI][uefi] mode, depending on the detected hardware capabilities.

Logical volume management is handled by [LVM][lvm], including a volume for swap (allowing for hibernation).

If enabled, full disk encryption is handled by [LUKS][luks], using the [LVM on LUKS][lvm-on-luks] method.

The file system is formatted using [Btrfs][btrfs] with [subvolumes][btrfs-subvolumes].

[Processor microcode updates][microcode] will be installed according to the system's CPU vendor.

[Early KMS start][early-kms-start] is enabled for any recognized GPU chipsets.

Any wireless connections created during the install will be persisted to the installed system.

A privileged user (i.e. a user allowed to use `sudo`) will be created and the root account will be disabled.

The following services are installed and enabled:

- [fstrim][ssd] (if installation disk is a solid-state drive)
- [iwd] (if wireless devices are present)
- [systemd-networkd]
- [systemd-resolved] (using `stub-resolv.conf` for name resolution)
- [systemd-timesyncd]
- [reflector]
- [sshd] (with root password authentication disabled)

## Usage

In general, the installation steps are as follows:

1. Boot into the [Arch Linux ISO][archiso]
1. Change the directory to this repository
1. Set `INSTALL_DEVICE` and any overrides (see [environment variables](#environment-variables))
1. Prepare the environment: `source ./scripts/prepare [CONFIG_DIR]`
1. Run the installation script: `./scripts/install`

After installation, the system is left mounted for inspection or
further configuration.

If all is well, `poweroff` and eject the installation media.

## Configuration

The resulting system is described by a [configuration directory](#configuration-files).
The default configuration directory at `./config` is what I consider a reasonable starting point based on the opinions outlined above.

The details of a _particular_ system are controlled entirely by [environment variables](#environment-variables).
These can be set manually, added to `$CONFIG_DIR/env`, or sourced from another file.
The only required variable is `INSTALL_DEVICE`, but you'll probably want to set more.

Once the desired variable overrides are set, source the preparation script to fill in the blanks.
If the script succeeds, a list of all the relevant environment variables and their values will be displayed as a sanity check (with sensitive information hidden).

The first argument to the preparation script is the configuration directory.
If omitted, it will use the default one.

To prepare the environment for the default configuration:

```sh
source ./scripts/prepare
```

The command above is equivalent to:

```sh
source ./scripts/prepare ./config
```

To prepare the environment for an alternate configuration:

```sh
source ./scripts/prepare /path/to/another/config
```

### Environment Variables

Any of the following variables can be defined anywhere, as long as they're exported in the environment used to perform the installation.

**NOTE**: Boolean values should be specified as `0` (false) or `1` (true).

- `INSTALL_DEVICE`: The disk that will contain the new system (required, e.g. `/dev/sda`, **WARNING**: all data will be destroyed without confirmation)

#### Host Identification

- `INSTALL_HOSTNAME`: The system host name (default: `arch`)

#### Locale

- `INSTALL_LANG`: The system language (default: `en_US.UTF-8`)
- `INSTALL_FONT`: The system console font (default: `Lat2-Terminus16`)
- `INSTALL_KEYMAP`: The system keyboard mapping (default: `us`)
- `INSTALL_TIMEZONE`: The system time zone (default: `UTC`)
- `INSTALL_REFLECTOR_COUNTRY`: The country used for pacman mirror selection by reflector (default: `US`, possible values: run `reflector --list-countries`)

#### Privileged User

- `INSTALL_SUDOER_USERNAME`: The primary privileged user's name (default: `admin`)
- `INSTALL_SUDOER_PASSWORD`: The primary privileged user's password (default: `hunter2`)
- `INSTALL_SUDOER_SHELL`: The primary privileged user's shell (default: same as the default for `useradd`)
- `INSTALL_SUDOER_GROUP`: The group name used to determine privileged user status (default: `wheel`)
- `INSTALL_SUDOER_GROUP_NOPASSWD`: A boolean indicating that users in the group `$INSTALL_SUDOER_GROUP` should be allowed access to `sudo` without authenticating

#### Hardware

- `INSTALL_CPU_VENDOR`: The vendor of the system's CPU (default: automatically determined from `vendor_id` in `/proc/cpuinfo`, possible values: `intel` or `amd`)
- `INSTALL_GPU_MODULES`: The kernel modules used by the system's GPUs (e.g. `i915`, default: automatically determined from the output of `lspci -k`, multiple values should be separated with a space)
- `INSTALL_BOOT_FIRMWARE`: The firmware used for booting (default: automatically determined based on the presence of `/sys/firmware/efi/efivars`, possible values: `bios` or `uefi`)
- `INSTALL_DEVICE_IS_SSD`: A boolean indicating whether or not the installation disk is a solid-state drive (default: automatically determined based on the value in `/sys/block/$(basename $INSTALL_DEVICE)/queue/rotational`)
- `INSTALL_NET_HAS_WIRELESS`: A boolean indicating the presence of a wireless network device (default: automatically determined based on the presence of devices named like `wl*`)
- `INSTALL_CONSOLEBLANK`: The number of seconds of inactivity to wait before putting the display to sleep (default: `0`, i.e. disabled) (corresponds to the `consoleblank` kernel parameter)

#### Partition Table

**NOTE**: Sizes for partition start and end must be specified in a way that [parted(8)][parted] can understand

- `INSTALL_BOOT_PART_NAME`: The name of the boot partition (default: `boot`)
- `INSTALL_BOOT_PART_START`: The start of the boot partition (default: `0%`)
- `INSTALL_BOOT_PART_END`: The end of the boot partition (default: `512MiB` for UEFI, `2MiB` for BIOS)
- `INSTALL_OS_PART_NAME`: The name of the operating system partition (default: `os`)
- `INSTALL_OS_PART_START`: The start of the operating system partition (default: `$INSTALL_BOOT_PART_END`)
- `INSTALL_OS_PART_END`: The end of the operating system partition (default: `100%`)

#### Mount Points

- `INSTALL_MOUNT`: The path where the new system will be mounted during installation (default: `/mnt/install`)
- `INSTALL_UEFI_MOUNT`: The path where the EFI partition will be mounted (if applicable, default: `/boot/efi`)

#### Full Disk Encryption

- `INSTALL_DEVICE_IS_ENCRYPTED`: A boolean dictating whether or not to use full disk encryption
- `INSTALL_LUKS_PASSPHRASE`: The passphrase to use for full disk encryption (default: `hunter2`, occupies key slot 0)
- `INSTALL_LUKS_ROOT_KEYFILE`: The path of the keyfile used to allow the initrd to unlock the root filesystem without asking for the passphrase again (default: `/crypto_keyfile.bin`, which is the default value used by `mkinitcpio`, occupies key slot 1)
- `INSTALL_LUKS_MAPPER_NAME`: The mapper name used for the encrypted partition (default: `os`)

#### Volume Management

**NOTE**: Sizes must be specified in a way that [lvcreate(8)][lvcreate] can understand.

- `INSTALL_LVM_VG_NAME`: The volume group name (default: `vg`)
- `INSTALL_LVM_SWAP_LV_NAME`: The name for the swap logical volume (default: `swap`)
- `INSTALL_LVM_SWAP_LV_SIZE`: The size of the swap logical volume (default: the same size as physical memory, i.e. the output of `./bin/guess-mem-total`)
- `INSTALL_LVM_ROOT_LV_NAME`: The name for the root logical volume (default: `root`)
- `INSTALL_LVM_ROOT_LV_EXTENTS`: The extents of the root logical volume (default: `+100%FREE`)

#### File System

- `INSTALL_FS_SWAP_LABEL`: The label for the swap file system (default: `swap`)
- `INSTALL_FS_ROOT_LABEL`: The label for the root file system (default: `root`)
- `INSTALL_FS_MOUNT_OPTIONS`: The mount options used for the root and swap volumes (default: `autodefrag,compress=zstd`)

### Configuration Files

Within a configuration directory, the following files are recognized:

#### `$CONFIG_DIR/env`

This file, if it exists, will be sourced at the beginning of the preparation script.
It's treated as a bash script, and any variablesrelevant to installation (see [environment variables][#environment-variables]) should be exported.

#### `$CONFIG_DIR/subvolumes`

This file, if it exists, defines the extra [btrfs subvolumes][btrfs-subvols] that will be created.
This should not include the root subvolume, as its presence and mount point is not optional.
It will always be created and mounted at `/` (`INSTALL_MOUNT` or `/mnt/install` during installation).

If it's executable, it should output one subvolume mapping per line to stdout.
If it's a regular file, it should contain one subvolume mapping per line with no blank lines or comments.

Every line must be of the form:

```
name /path/to/subvolume
```

#### `$CONFIG_DIR/packages`

This file, if it exists, defines the extra packages that will be installed on the new system.

If it's executable, it should output one package per line to stdout.
If it's a regular file, it should contain one package per line with no blank lines or comments.

Aside from these extra packages, only the packages necessary for a functional system will be installed.

#### `$CONFIG_DIR/install`

This script, if it exists, will be run in a chroot just after packages have been installed.

#### `$CONFIG_DIR/templates/*`

This directory tree contains files necessary for installation, but with potentially varying details.

#### `$CONFIG_DIR/files/*`

This directory tree, if it exists, contains files that will be added unchanged to the installation.
It will be `rsync`ed to `/` with the permissions (but not ownership) intact.

## Installation

After the preparation script is sourced, the only other necessary step is to run the installation script:

```sh
./scripts/install
```

This script is intentionally kept extremely simple and easy to read.
It serves as a good overview of the installation process.
As `./bin` is now in `PATH`, feel free to execute each step separately to verify they're working as intended.

The commands can also be useful outside of the context of installation.
For example, the following can be used to mount an existing system (provided the configuration directory and environment match):

```sh
luks-open
swap-open
fs-mount
```

### Initialize the SSH server and enable Multicast DNS

If you want or need to manage the installation over SSH, the `./scripts/init` script can make this easier.
It does the following:

- Authorizes the SSH keys with write access to this repository
- Enables [Multicast DNS][mdns], making `archiso.local` reachable
- Fetches an archive of this repository into `/root` (if necessary)

If you already have access to the repository in the live environment, just run the script:

```sh
./scripts/init
```

If you need to download the repository too, `curl` the script into bash:

```sh
curl https://github.com/jmcantrell/bootstrap-arch/raw/main/scripts/init | bash -s
```

If the network is available automatically after booting, you could also run the script by using the `script` boot parameter, recognized by the Arch Linux ISO.

When you see the GRUB menu as the live environment is booting, press <kbd>Tab</kbd> to edit the kernel command line and add the following:

```
script=https://github.com/jmcantrell/bootstrap-arch/raw/main/scripts/init
```

The script will be run similarly to the curl method above as soon as the environment is ready.

[archiso]: https://archlinux.org/download/
[btrfs-subvolumes]: https://wiki.archlinux.org/title/Btrfs#Subvolumes
[btrfs]: https://wiki.archlinux.org/title/Btrfs
[early-kms-start]: https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start
[gpt]: https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
[grub]: https://wiki.archlinux.org/title/GRUB
[guide]: https://wiki.archlinux.org/title/Installation_guide
[iwd]: https://wiki.archlinux.org/title/Iwd
[luks]: https://wiki.archlinux.org/title/Dm-crypt
[lvcreate]: https://man.archlinux.org/man/core/lvm2/lvcreate.8.en
[lvm-on-luks]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[lvm]: https://wiki.archlinux.org/title/LVM
[mdns]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[microcode]: https://wiki.archlinux.org/title/Microcode
[parted]: https://man.archlinux.org/man/extra/parted/parted.8.en
[reflector]: https://wiki.archlinux.org/title/Reflector
[ssd]: https://wiki.archlinux.org/title/Solid_state_drive
[sshd]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[systemd-networkd]: https://wiki.archlinux.org/title/Systemd-networkd
[systemd-resolved]: https://wiki.archlinux.org/title/Systemd-resolved
[systemd-timesyncd]: https://wiki.archlinux.org/title/Systemd-timesyncd
[uefi]: https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface
