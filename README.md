# arch-bootstrap

An opinionated Arch Linux installer.

Aside from the opinions listed below, the target system should closely match the result of following the [official installation guide][install].

## Opinions

Components used:

- [GRUB][grub] boot loader using either [BIOS][grub-bios] or [UEFI][grub-uefi], depending on the [boot firmware](#boot-firmware) interface
- [LVM][lvm] with an [optional](#swap-volume) [dedicated swap volume][swap-partition]
- [Optional](#full-disk-encryption) [full disk encryption][luks] using the [LVM on LUKS][lvm-on-luks] method
- [Btrfs] [file system](#file-system) with [subvolumes][btrfs-subvolumes] (see `./config/btrfs/subvolumes`)
- [Processor microcode updates][microcode] for the [CPU vendor](#processor)
- [Early KMS start][early-kms-start] for any [graphics chip sets](#graphics)

Enabled systemd units:

- [systemd-networkd].service (with [Multicast DNS][mdns] enabled)
- [systemd-resolved].service (with `stub-resolv.conf`)
- [systemd-timesyncd].service
- [reflector].{service,timer}
- [sshd].service
- [fstrim][ssd-trim].timer (if trim is configured)
- [iwd].service (if wireless networking is configured)

Additional configuration:

- If [wireless networking is enabled](#wireless-networking), any [networks established][iwd-networks] in the live system will be persisted to the target system
- If [trim is enabled or the installation disk is a solid-state drive](#solid-state-drive), discards will be configured in [LVM][lvm-thin] and [LUKS][luks-trim]
- A [privileged user](#privileged-user) will be created and the root account will be locked
- Any SSH public keys authorized in the live system will be authorized for the privileged user

See [configuration](#configuration) for complete details on customizing the installation.

## Usage

Boot into the [live environment][iso] and change the directory to this repository.

Set [environment variables](#configuration) to configure installation:

```sh
export BOOTSTRAP_TARGET_DEVICE=/dev/sda
export BOOTSTRAP_ADMIN_LOGIN=bob
export BOOTSTRAP_MIRROR_SORT=rate
export BOOTSTRAP_TIMEZONE=America/Chicago
export BOOTSTRAP_USE_LUKS=1
```

Initialize the environment on the live system:

```sh
source ./scripts/init
```

This will validate the environment variables that were set and add `./bin` to `PATH`.

Inspect the modified environment:

```sh
print-config
```

Install the target system:

```sh
install-target
```

After installation, the target system is left mounted for inspection or further configuration.

If all is well, `poweroff` and eject the installation media.

The top-level commands, i.e., `./bin/*-target`, are intentionally kept extremely simple and easy to read, serving as an outline.
They can also be helpful in other contexts, e.g., troubleshooting the target system (see `./bin/{open,close,remove,wipe,shred}-target`).

### Offline Installation

An [offline package repository][offline-install] can be used to minimize bandwidth usage or if the network is not available.

Transfer the repository to the live system and assign it to `BOOTSTRAP_PACKAGE_REPO_DIR`.
During installation, packages will be pulled **only** from this repository.

To create a package repository at `/var/cache/bootstrap/repo` based on packages defined in `./config/packages/**`:

```sh
./scripts/mkrepo
```

Extra packages can be provided as arguments to the script:

```sh
./scripts/mkrepo tmux git
```

To see complete usage details:

```sh
./scripts/mkrepo --help
```

### Automated Installation

The Arch Linux ISO uses [cloud-init] which can be configured to automate the installation.

The script `./scripts/mkci` can be used to create a cloud-init ISO (requires `xorriso`, `jo`, and `yq`).

The generated image will be configured to do the following automatically:

- Authorize any SSH public keys added to ssh-agent
- Authorize any SSH public keys in `~/.ssh/authorized_keys`
- Authorize any SSH public keys in `~/.ssh` belonging to the user
- Include any iwd pre-shared keys on the system
- Enable Multicast DNS on the live system so it can be reached by host name
- Set the host name of the live system to `$BOOTSTRAP_HOSTNAME` (if the environment variable is set)
- Try to mount a drive with the label `BOOTSTRAP` to `/mnt/bootstrap`
- Try to mount a drive with the label `PACKAGES` to `/mnt/packages`
- Add any configuration (exported environment variables like `BOOTSTRAP_*`) to the file `/root/config` on the live system.
- Create an installation entry point script at `/root/install` on the live system that logs its output to `/root/install.log` and `/var/log/install.log` on the target system.

To see complete usage details:

```sh
./scripts/mkci --help
```

### Virtual Machine Installation

The script `./scripts/mkvm` can be used to bootstrap a virtual machine (requires `qemu`, `xorriso`, `jo`, and `yq`).

The virtual machine will be booted with a cloud-init image generated using the [script described earlier](#automated-installation).

Additionally, it will do the following:

- Mount the current directory on the host system to `/mnt/bootstrap` on the live system
- Mount `/var/cache/bootstrap/repo` on the host system to `/mnt/packages` on the live system and [configure offline installation](#offline-installation)
- Forward TCP port `60022` (or argument to option `-p`) on the host system to TCP port `22` on the virtual machine
- Allow SSH connections over vsock at client id `42` (or argument to option `-c`)

To create a virtual machine with the default settings (only the installation disk set):

```sh
./scripts/mkvm /path/to/archlinux.iso /path/to/disk.cow
```

To add certain settings, export them before running the script:

```sh
export BOOTSTRAP_HOSTNAME=box
export BOOTSTRAP_TIMEZONE=America/Chicago
export BOOTSTRAP_ADMIN_LOGIN=frank

./scripts/test /path/to/archlinux.iso /path/to/disk.cow
```

To see complete usage details:

```sh
./scripts/mkvm --help
```

### Remote Installation

The script `./scripts/inject` can make installation over SSH easier:

It will do the following on the live system:

- Authorize the SSH keys with write access to this repository
- Enable Multicast DNS so the live system can be reached by host name
- Fetch an archive of this repository into `/tmp/bootstrap` (if the script is not run locally)

If you already have access to the repository in the live system, just run the script to authorize the keys and enable mDNS:

```sh
./scripts/inject
```

To also download the repository, `curl` the script into `bash`:

```sh
curl https://git.sr.ht/~jmcantrell/arch-bootstrap/blob/main/scripts/inject | bash -s
```

If the network is available automatically after booting, you could run the script by using the `script` boot parameter.
When you see the GRUB menu, press <kbd>Tab</kbd> to edit the kernel command line and add the following:

```
script=https://git.sr.ht/~jmcantrell/arch-bootstrap/blob/main/scripts/inject
```

The script will be run similarly to the curl command above once the live system has booted.

## Configuration

The details of the system being installed are controlled entirely by environment variables.
The following variables should be defined and exported before sourcing the initialization script.

### Installation Disk

- `BOOTSTRAP_TARGET_DEVICE`: The disk that will contain the new system (**REQUIRED**, e.g. `/dev/sda`, **WARNING**: all existing data will be destroyed without confirmation)
- `BOOTSTRAP_TARGET_MOUNT_DIR`: The path where the new system will be mounted during installation (default: `/mnt/target`)

### Hardware

#### Boot Firmware

- `BOOTSTRAP_BOOT_FIRMWARE`: The boot firmware interface (default: `uefi` if `/sys/firmware/efi/efivars` exists, otherwise `bios`)

#### Processor

- `BOOTSTRAP_CPU_VENDOR`: The vendor of the system's CPU (default: parsed from `vendor_id` in `/proc/cpuinfo`, see `./bin/print-cpu-vendor`, choices: `intel` or `amd`)

#### Graphics

- `BOOTSTRAP_GPU_MODULES`: The kernel modules used by the system's GPUs (e.g. `i915`, default: automatically determined from the output of `lspci -k`, see `./bin/print-gpu-modules`, multiple values should be separated with a space)

#### Solid-State Drive

- `BOOTSTRAP_USE_TRIM`: If set to a non-empty value, enable trim support for LUKS (if applicable) and LVM, and enable scheduled `fstrim` (default: set if device is not a disk with spinning platters, see `./bin/is-rotational-disk`)

#### Wireless Networking

- `BOOTSTRAP_USE_WIRELESS`: If set to a non-empty value, enable wireless networking (default: set if there are any network interfaces starting with `wl`, see `./bin/print-network-interfaces`)

### Partition Table

**NOTE**: Values for partition sizes must be specified in a way that [sfdisk(8)][sfdisk] can understand.

#### Boot Partition

- `BOOTSTRAP_PART_BOOT_NAME`: The name of the boot partition (default: `boot`)
- `BOOTSTRAP_PART_BOOT_SIZE`: The size of the boot partition (default: `100M` for UEFI, `1M` for BIOS)
- `BOOTSTRAP_UEFI_MOUNT_DIR`: The path where the EFI partition will be mounted (if applicable, default: `/efi`)

#### System Partition

- `BOOTSTRAP_PART_SYS_NAME`: The name of the operating system partition (default: `sys`)
- `BOOTSTRAP_PART_SYS_SIZE`: The size of the operating system partition (default: `+`, i.e., use all remaining space)

### Full Disk Encryption

**NOTE**: The main passphrase (slot 0) will be requested at the beginning of the installation.

- `BOOTSTRAP_USE_LUKS`: If set to a non-empty value, use full disk encryption for `$BOOTSTRAP_TARGET_DEVICE`
- `BOOTSTRAP_LUKS_MAPPER_NAME`: The mapper name used for the encrypted partition (default: `sys`)
- `BOOTSTRAP_LUKS_INITRD_KEY_FILE`: The key file used by the kernel to unlock the system without asking for the passphrase again (default: `/crypto_keyfile.bin`, slot 1, generated on demand)

### Volume Management

**NOTE**: Values for volume size and extents must be specified in a way that [lvcreate(8)][lvcreate] can understand.

- `BOOTSTRAP_LVM_VG_NAME`: The volume group name (default: `sys`)

#### Swap Volume

- `BOOTSTRAP_USE_SWAP`: If set to a non-empty value, create a swap volume, allowing for hibernation
- `BOOTSTRAP_LVM_LV_SWAP_NAME`: The name for the swap logical volume (default: `swap`)
- `BOOTSTRAP_LVM_LV_SWAP_SIZE`: The size of the swap logical volume (default: same size as physical memory, i.e., parsed from the output of `dmidecode`, see `./bin/print-memory-size`)

#### Root Volume

- `BOOTSTRAP_LVM_LV_ROOT_NAME`: The name for the root logical volume (default: `root`)
- `BOOTSTRAP_LVM_LV_ROOT_EXTENTS`: The extents of the root logical volume (default: `+100%FREE`, i.e., use all remaining space)

### File System

- `BOOTSTRAP_FS_SWAP_LABEL`: The label for the swap file system (default: `swap`)
- `BOOTSTRAP_FS_ROOT_LABEL`: The label for the root file system (default: `root`)

### Kernel

- `BOOTSTRAP_KERNEL_USE_LTS`: If set to a non-empty value, set the LTS kernel as the default
- `BOOTSTRAP_KERNEL_QUIET`: If set to a non-empty value, include `quiet` in the kernel parameters
- `BOOTSTRAP_KERNEL_LOGLEVEL`: Kernel log level (default: 4)
- `BOOTSTRAP_KERNEL_CONSOLEBLANK`: The number of seconds of inactivity to wait before putting the display to sleep (default: 0, i.e., disabled)

### Networking

- `BOOTSTRAP_HOSTNAME`: The system host name (default: `arch`)

### Localization

- `BOOTSTRAP_LANG`: The default language (default: `en_US.UTF-8`)
- `BOOTSTRAP_KEYMAP`: The default keyboard mapping (default: `us`)
- `BOOTSTRAP_TIMEZONE`: The system time zone (default: the time zone set in the live environment, i.e., from `/etc/localtime`, or `UTC` if it's not set)

### Mirrors

- `BOOTSTRAP_MIRROR_SORT`: The sort criteria used for mirror selection (default: `age`, choices: `age`, `rate`, `score`, or `delay`)
- `BOOTSTRAP_MIRROR_LATEST`: Only consider the n most recently synchronized mirrors (default: 5)
- `BOOTSTRAP_MIRROR_COUNTRY`: The country used for mirror selection (default: `US`, choices: see `reflector --list-countries`)

### Packages

- `BOOTSTRAP_PACKAGE_REPO_DIR`: Look for packages in this offline package repository directory

### Privileged User

**NOTE**: The privileged user's password will be requested at the end of the installation.

- `BOOTSTRAP_ADMIN_LOGIN`: The privileged user's login (default: `admin`)
- `BOOTSTRAP_ADMIN_GROUP`: The group used to determine privileged user status (default: `wheel`)

## Testing

Installation can be tested in a virtual machine using the script `./scripts/test`.

The ephemeral virtual machine will be created using the [script described earlier](#virtual-machine-installation).

After powering off the live system, the new system will be booted.

To test the default settings (only the installation disk set):

```sh
./scripts/test /path/to/archlinux.iso
```

To test out certain settings, export them before running the script:

```sh
export BOOTSTRAP_HOSTNAME=box
export BOOTSTRAP_TIMEZONE=America/Chicago
export BOOTSTRAP_ADMIN_LOGIN=frank

./scripts/test /path/to/archlinux.iso
```

To see complete usage details:

```sh
./scripts/test --help
```

[btrfs-subvolumes]: https://wiki.archlinux.org/title/Btrfs#Subvolumes
[btrfs]: https://wiki.archlinux.org/title/Btrfs
[cloud-init]: https://wiki.archlinux.org/title/Cloud-init
[early-kms-start]: https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start
[fstrim]: https://wiki.archlinux.org/title/Solid_state_drive#Periodic_TRIM
[gpt]: https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
[grub-bios]: https://wiki.archlinux.org/title/GRUB#BIOS_systems
[grub-uefi]: https://wiki.archlinux.org/title/GRUB#UEFI_systems
[grub]: https://wiki.archlinux.org/title/GRUB
[hibernation]: https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation
[install]: https://wiki.archlinux.org/title/Installation_guide
[iso]: https://archlinux.org/download/
[iwd-networks]: https://wiki.archlinux.org/title/Iwd#Network_configuration
[iwd]: https://wiki.archlinux.org/title/Iwd
[kernel]: https://wiki.archlinux.org/title/Kernel
[luks-trim]: https://wiki.archlinux.org/title/Dm-crypt/Specialties#Discard/TRIM_support_for_solid_state_drives_(SSD)
[luks]: https://wiki.archlinux.org/title/Dm-crypt
[lvcreate]: https://man.archlinux.org/man/core/lvm2/lvcreate.8.en
[lvm-on-luks]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[lvm-thin]: https://wiki.archlinux.org/title/LVM#Thin_provisioning
[lvm]: https://wiki.archlinux.org/title/LVM
[mdns]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[microcode]: https://wiki.archlinux.org/title/Microcode
[offline-install]: https://wiki.archlinux.org/title/Offline_installation
[reflector]: https://wiki.archlinux.org/title/Reflector
[sfdisk]: https://man.archlinux.org/man/sfdisk.8
[ssd-trim]: https://wiki.archlinux.org/title/Solid_state_drive#TRIM
[ssd]: https://wiki.archlinux.org/title/Solid_state_drive
[sshd]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[swap-partition]: https://wiki.archlinux.org/title/Swap#Swap_partition
[systemd-networkd]: https://wiki.archlinux.org/title/Systemd-networkd
[systemd-resolved]: https://wiki.archlinux.org/title/Systemd-resolved
[systemd-timesyncd]: https://wiki.archlinux.org/title/Systemd-timesyncd
