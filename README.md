# bootstrap-arch

A mildly-opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the resulting system closely matches what you would get from following the [official installation guide][install].

## Opinions

Boot loading is handled by [GRUB][grub] with a [GPT][gpt] partition table using BIOS or [UEFI][uefi] mode, depending on the detected hardware capabilities.

Logical volume management is handled by [LVM][lvm], including a volume for swap (allowing for hibernation).

If enabled, full disk encryption is handled by [LUKS][luks], using the [LVM on LUKS][lvm-on-luks] method.

The file system is formatted using [btrfs] with [subvolumes][btrfs-subvolumes] (see `./config/subvolumes`).

[Processor microcode updates][microcode] will be installed according to the system's CPU vendor.

[Early KMS start][early-kms-start] is enabled for any recognized GPU chipsets.

Any wireless connections created in the installation environment will be persisted to the installed system.

Optionally, a privileged user can be created, in which case the root account will be disabled.

The following services/timers are enabled:

- [fstrim][ssd] (if installation disk is a solid-state drive)
- [iwd] (if wireless devices are present)
- [systemd-networkd] (with [Multicast DNS][mdns] enabled)
- [systemd-resolved] (using `stub-resolv.conf`)
- [systemd-timesyncd]
- [reflector]
- [sshd] (with root password authentication disabled)

## Usage

In general, the installation steps are as follows:

1. Boot into the [Arch Linux ISO][iso]
1. Change the directory to this repository
1. Set required [environment](#environment) variables
1. Prepare the environment: `. ./scripts/prepare`
1. Run the installation script: `./scripts/install`

After installation, the system is left mounted for inspection or further configuration.

If all is well, `poweroff` and eject the installation media.

## Configuration

The desired system is described by a [configuration directory](#configuration-files).
The default configuration directory at `./config` is what I consider a reasonable starting point based on the opinions outlined earlier and should serve as a template for customization.
The details of that system are controlled entirely by [environment](#environment).
These can be set manually, added to `$INSTALL_CONFIG/env`, or sourced from another file before sourcing the prepare script.

Once the necessary variable overrides are set, source the preparation script to fill in the blanks.
If the script succeeds, a list of all the relevant environment variables and their values will be displayed as a sanity check (with sensitive information hidden).

To prepare the environment for the default configuration:
```sh
source ./scripts/prepare
```

To prepare the environment for a different configuration:
```sh
source ./scripts/prepare /path/to/config/dir
```

Which is equivalent to:
```sh
INSTALL_CONFIG=/path/to/config/dir source ./scripts/prepare
```

### Environment

The following variables can be defined anywhere, as long as they're exported in the environment used to perform the installation.

#### Metadata

- `INSTALL_DEVICE`: The disk that will contain the new system (**REQUIRED**, e.g. `/dev/sda`, **WARNING**: all existing data will be destroyed without confirmation)
- `INSTALL_CONFIG`: The directory containing [configuration files](#configuration-files) (default: `./config`)
- `INSTALL_MOUNT`: The path where the new system will be mounted during installation (default: `/mnt/install`)

#### Host Details

- `INSTALL_HOSTNAME`: The system host name (default: `arch`)
- `INSTALL_LANG`: The default language (default: `en_US.UTF-8`)
- `INSTALL_KEYMAP`: The default keyboard mapping (default: `us`)
- `INSTALL_FONT`: The default console font
- `INSTALL_TIMEZONE`: The system time zone (default: the timezone set in the live environment, i.e., from `/etc/localtime`, or "UTC" if it's not set)

#### Packages

- `INSTALL_MIRROR_COUNTRY`: The country used for mirror selection (default: `US`, possible values: run `reflector --list-countries`)
- `INSTALL_PARALLEL_DOWNLOADS`: If set, enable parallel package downloads; if set to a positive integer, also define the number of parallel downloads

#### Users

- `INSTALL_ROOT_PASSWORD`: The root account password (only used if not setting a privileged user, default: `hunter2`)
- `INSTALL_SUDOER_LOGIN`: The primary privileged user's login (if set, the root account will be disabled)
- `INSTALL_SUDOER_PASSWORD`: The primary privileged user's password (default: `hunter2`)
- `INSTALL_SUDOER_SHELL`: The primary privileged user's shell (default: same as the default for `useradd`)
- `INSTALL_SUDOER_GROUP_NAME`: The group name used to determine privileged user status (default: `wheel`)
- `INSTALL_SUDOER_GROUP_NOPASSWD`: If set, users in the group will be allowed to use `sudo` without authenticating
- `INSTALL_SUDOER_GROUP_SPEC`: The sudoer specification that will be put in `/etc/sudoers.d/group` (default: `%<group> ALL=(ALL) ALL` or `%<group> ALL=(ALL) NOPASSWD:ALL` depending on the previous setting)

#### Hardware

- `INSTALL_CPU_VENDOR`: The vendor of the system's CPU (default: parsed from `vendor_id` in `/proc/cpuinfo`, see `./bin/get-cpu-vendor`, choices: `intel` or `amd`)
- `INSTALL_GPU_MODULES`: The kernel modules used by the system's GPUs (e.g. `i915`, default: automatically determined from the output of `lspci -k`, see `./bin/get-gpu-modules`, multiple values should be separated with a space)
- `INSTALL_BOOT_FIRMWARE`: The firmware used for booting (default: `uefi` if `/sys/firmware/efi/efivars` exists, otherwise `bios`)
- `INSTALL_DEVICE_USE_TRIM`: If set, enable trim support where possible (default: set if device is an SSD, see `./bin/is-device-ssd`)
- `INSTALL_NET_USE_WIRELESS`: If set, enable wireless networking (default: set if there are any network interfaces named like `wl*`, see `./bin/get-network-interfaces`)

#### Partition Table

**NOTE**: Values for partition start and size must be specified in a way that [sfdisk(8)][sfdisk] can understand

- `INSTALL_PART_BOOT_NAME`: The name of the boot partition (default: `boot`)
- `INSTALL_PART_BOOT_START`: The start of the boot partition
- `INSTALL_PART_BOOT_SIZE`: The end of the boot partition (default: `100M` for UEFI, `1M` for BIOS)
- `INSTALL_PART_SYS_NAME`: The name of the operating system partition (default: `sys`)
- `INSTALL_PART_SYS_START`: The start of the operating system partition
- `INSTALL_PART_SYS_SIZE`: The end of the operating system partition (default: `+`, i.e., use all remaining space)
- `INSTALL_UEFI_MOUNT`: The path where the EFI partition will be mounted (if applicable, default: `/efi`)

#### Full Disk Encryption

- `INSTALL_DEVICE_USE_LUKS`: Set to indicate use of full disk encryption for `$INSTALL_DEVICE`
- `INSTALL_LUKS_PASSPHRASE`: The passphrase to use for full disk encryption (default: `hunter2`, occupies key slot 0)
- `INSTALL_LUKS_KEYFILE`: The path of the keyfile used to allow the initrd to unlock the system without asking for the passphrase again (default: `/crypto_keyfile.bin`, occupies key slot 1)
- `INSTALL_LUKS_MAPPER_NAME`: The mapper name used for the encrypted partition (default: `sys`)

#### Volume Management

**NOTE**: Values for volume size and extents must be specified in a way that [lvcreate(8)][lvcreate] can understand.

- `INSTALL_LVM_VG_NAME`: The volume group name (default: `vg`)
- `INSTALL_LVM_SWAP_LV_NAME`: The name for the swap logical volume (default: `swap`)
- `INSTALL_LVM_SWAP_LV_SIZE`: The size of the swap logical volume (default: same size as physical memory, i.e., parsed from the output of `dmidecode`, see `./bin/get-memory-size`)
- `INSTALL_LVM_ROOT_LV_NAME`: The name for the root logical volume (default: `root`)
- `INSTALL_LVM_ROOT_LV_EXTENTS`: The extents of the root logical volume (default: `+100%FREE`)

#### File System

- `INSTALL_FS_SWAP_LABEL`: The label for the swap file system (default: `swap`)
- `INSTALL_FS_ROOT_LABEL`: The label for the root file system (default: `root`)
- `INSTALL_FS_ROOT_OPTIONS`: The mount options used for file systems (default: `autodefrag,compress=zstd`)

#### Kernel

- `INSTALL_KERNEL_VARIANT`: Kernel variant to use (e.g., `zen` or `lts`)
- `INSTALL_KERNEL_QUIET`: If set, include `quiet` in kernel parameters
- `INSTALL_KERNEL_LOGLEVEL`: Kernel log level (default: `3`)
- `INSTALL_KERNEL_CONSOLEBLANK`: The number of seconds of inactivity to wait before putting the display to sleep (default: `0`, i.e., disabled)
- `INSTALL_KERNEL_EXTRA_PARAMS`: Extra kernel parameters to include 

### Configuration Files

Within a configuration directory, the following files are recognized:

#### `$INSTALL_CONFIG/env`

This file, if it exists, will be sourced at the beginning of the preparation script.
It's treated as a bash script, and any variables relevant to installation (see [environment](#environment)) should be exported.

#### `$INSTALL_CONFIG/subvolumes`

This file, if it exists, defines the extra btrfs subvolumes that will be created.
This should **not** include the root subvolume, as its presence and mount point is not optional.
It will always be created and mounted at `/`.

If it's executable, it should output one subvolume mapping per line to stdout.
If it's a regular file, it should contain one subvolume mapping per line with no blank lines or comments.

Every line must be of the form:
```
name /path/to/subvolume
```

See `./config/subvolumes` for the default list.

#### `$INSTALL_CONFIG/packages`

This file, if it exists, defines the extra packages that will be installed on the new system.

If it's executable, it should output one package per line to stdout.
If it's a regular file, it should contain one package per line with no blank lines or comments.

Aside from these extra packages, only the packages necessary for a functional system will be installed (see `./bin/list-packages`).

By default, `./config/packages` does not exist, i.e., no extra packages are installed.

#### `$INSTALL_CONFIG/install`

This script, if it exists, will be run in a chroot just before finalization steps (boot loader configuration and initrd creation)

#### `$INSTALL_CONFIG/templates/*`

This directory tree contains files necessary for installation, but with potentially varying details.

#### `$INSTALL_CONFIG/files/*`

This directory tree, if it exists, contains files that will be added unchanged to the installation.
It will be copied to `/` with the permissions (but not ownership) intact.

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

If you want or need to manage the installation over SSH, the `./scripts/inject` script can make this easier.
It does the following:

- Authorizes the SSH keys with write access to this repository
- Enables Multicast DNS, making `archiso.local` reachable
- Fetches an archive of this repository into `/root` (if necessary)

If you already have access to the repository in the live environment, just run the script:
```sh
./scripts/inject
```

If you need to download the repository too, `curl` the script into bash:
```sh
curl https://git.sr.ht/~jmcantrell/bootstrap-arch/blob/main/scripts/inject | bash -s
```

If the network is available automatically after booting, you could also run the script by using the `script` boot parameter, recognized by the Arch Linux ISO.

When you see the GRUB menu as the live environment is booting, press <kbd>Tab</kbd> to edit the kernel command line and add the following:
```
script=https://git.sr.ht/~jmcantrell/bootstrap-arch/blob/main/scripts/inject
```

The script will be run similarly to the curl method above as soon as the environment is ready.

[btrfs-subvolumes]: https://wiki.archlinux.org/title/Btrfs#Subvolumes
[btrfs]: https://wiki.archlinux.org/title/Btrfs
[early-kms-start]: https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start
[gpt]: https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
[grub]: https://wiki.archlinux.org/title/GRUB
[install]: https://wiki.archlinux.org/title/Installation_guide
[iso]: https://archlinux.org/download/
[iwd]: https://wiki.archlinux.org/title/Iwd
[luks]: https://wiki.archlinux.org/title/Dm-crypt
[lvcreate]: https://man.archlinux.org/man/core/lvm2/lvcreate.8.en
[lvm-on-luks]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[lvm]: https://wiki.archlinux.org/title/LVM
[mdns]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[microcode]: https://wiki.archlinux.org/title/Microcode
[reflector]: https://wiki.archlinux.org/title/Reflector
[sfdisk]: https://man.archlinux.org/man/sfdisk.8
[ssd]: https://wiki.archlinux.org/title/Solid_state_drive
[sshd]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[systemd-networkd]: https://wiki.archlinux.org/title/Systemd-networkd
[systemd-resolved]: https://wiki.archlinux.org/title/Systemd-resolved
[systemd-timesyncd]: https://wiki.archlinux.org/title/Systemd-timesyncd
[uefi]: https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface
