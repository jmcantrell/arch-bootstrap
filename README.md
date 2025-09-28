# arch-bootstrap

An opinionated unattended Arch Linux installer.

Aside from the opinions listed below, the resulting system should closely match what you would get from following the [official installation guide][install].

## Opinions

Boot loading is handled by [GRUB][grub] with a [GPT][gpt] partition table using BIOS or [UEFI][uefi] mode, depending on the detected hardware capabilities.

Logical volume management is handled by [LVM][lvm] with an optional swap volume, allowing for hibernation.

If enabled, [full disk encryption][fde] is implemented using the [LVM on LUKS][lvm-on-luks] method.

The file system is formatted using [btrfs] with [subvolumes][btrfs-subvolumes] (see `./config/btrfs/subvolumes`).

[Processor microcode updates][microcode] will be installed for the system's detected CPU vendor.

[Early KMS start][early-kms-start] is enabled for any recognized GPU chip sets.

A [privileged user](#privileged-user) will be created and the root account will be locked.

If wireless networking is used, any networks established in the installation environment will be persisted to the system.

Any SSH public keys authorized in the installation environment will be persisted to the system.

The following systemd units are enabled:

- [fstrim][ssd].timer (if installation disk is a solid-state drive)
- [iwd].service (if wireless networking is enabled)
- [systemd-networkd].service (with [Multicast DNS][mdns] enabled)
- [systemd-resolved].service (with `stub-resolv.conf`)
- [systemd-timesyncd].service
- [reflector].{service,timer}
- [sshd].service

## Usage

Boot into the [Arch Linux ISO][iso] and change the directory to this repository.

Set required environment variables:

```sh
export BOOTSTRAP_INSTALL_DEVICE=/dev/sda
```

Set any optional environment variables:

```sh
export BOOTSTRAP_ADMIN_LOGIN=bob
export BOOTSTRAP_MIRROR_SORT=rate
export BOOTSTRAP_TIMEZONE=America/Chicago
export BOOTSTRAP_USE_LUKS=1
```

Prepare the environment:

```sh
source ./scripts/prepare
```

Inspect the modified environment (sensitive data is redacted):

```sh
./scripts/inspect
```

Install the system:

```sh
./scripts/install
```

After installation, the system is left mounted for inspection or further configuration.

If all is well, `poweroff` and eject the installation media.

The scripts are intentionally kept extremely simple and easy to read, serving as an outline.
As `./bin` is in `PATH` after preparation, feel free to execute each step separately to verify they're working as intended.

The scripts can also be useful in other contexts (e.g., troubleshooting a system, see `./scripts/`).

### Usage over SSH

If you need to manage the installation over SSH, the injection script can make this easier.
It does the following:

- Authorizes the SSH keys with write access to this repository
- Fetches an archive of this repository into `/tmp/bootstrap` (if necessary)

If you already have access to the repository in the live environment, just run the script to authorize the keys:

```sh
./scripts/inject
```

To also download the repository, `curl` the script into `bash`:

```sh
curl https://git.sr.ht/~jmcantrell/arch-bootstrap/blob/main/scripts/inject | bash -s
```

If the network is available automatically after booting, you could run the script by using the `script` boot parameter, recognized by the Arch Linux ISO.

When you see the GRUB menu as during booting, press <kbd>Tab</kbd> to edit the kernel command line and add the following:

```
script=https://git.sr.ht/~jmcantrell/arch-bootstrap/blob/main/scripts/inject
```

The script will be run similarly to the curl method above as soon as the environment is ready.

## Configuration

The details of the system being installed are controlled entirely by environment variables.
The following variables should be defined and exported before sourcing the preparation script.

### Disk

- `BOOTSTRAP_INSTALL_DEVICE`: The disk that will contain the new system (**REQUIRED**, e.g. `/dev/sda`, **WARNING**: all existing data will be destroyed without confirmation)
- `BOOTSTRAP_MOUNT_DIR`: The path where the new system will be mounted during installation (default: `/mnt/install`)

### Hardware

- `BOOTSTRAP_BOOT_FIRMWARE`: The firmware used for booting (default: `uefi` if `/sys/firmware/efi/efivars` exists, otherwise `bios`)
- `BOOTSTRAP_CPU_VENDOR`: The vendor of the system's CPU (default: parsed from `vendor_id` in `/proc/cpuinfo`, see `./bin/print-cpu-vendor`, choices: `intel` or `amd`)
- `BOOTSTRAP_GPU_MODULES`: The kernel modules used by the system's GPUs (e.g. `i915`, default: automatically determined from the output of `lspci -k`, see `./bin/print-gpu-modules`, multiple values should be separated with a space)
- `BOOTSTRAP_USE_TRIM`: If set to a non-empty value, enable trim support for LUKS (if applicable) and LVM, and enable scheduled `fstrim` (default: set if device is not a disk with spinning platters, see `./bin/is-rotational-disk`)
- `BOOTSTRAP_USE_WIRELESS`: If set to a non-empty value, enable wireless networking (default: set if there are any network interfaces starting with `wl`, see `./bin/print-network-interfaces`)

### Partition Table

**NOTE**: Values for partition sizes must be specified in a way that [sfdisk(8)][sfdisk] can understand

#### Boot Partition

- `BOOTSTRAP_PART_BOOT_NAME`: The name of the boot partition (default: `boot`)
- `BOOTSTRAP_PART_BOOT_SIZE`: The size of the boot partition (default: `100M` for UEFI, `1M` for BIOS)
- `BOOTSTRAP_UEFI_MOUNT_DIR`: The path where the EFI partition will be mounted (if applicable, default: `/efi`)

#### System Partition

- `BOOTSTRAP_PART_SYS_NAME`: The name of the operating system partition (default: `sys`)
- `BOOTSTRAP_PART_SYS_SIZE`: The size of the operating system partition (default: `+`, i.e., use all remaining space)

### Full Disk Encryption

- `BOOTSTRAP_USE_LUKS`: If set to a non-empty value, use full disk encryption for `$BOOTSTRAP_INSTALL_DEVICE`
- `BOOTSTRAP_LUKS_PASSPHRASE`: The passphrase to use for full disk encryption (default: `$BOOTSTRAP_DEFAULT_PASSWORD`, occupies key slot 0)
- `BOOTSTRAP_LUKS_KEY_FILE`: The path of the key file used to allow the initrd to unlock the system without asking for the passphrase again (default: `/crypto_keyfile.bin`, occupies key slot 1, generated on demand)
- `BOOTSTRAP_LUKS_MAPPER_NAME`: The mapper name used for the encrypted partition (default: `sys`)

### Volume Management

**NOTE**: Values for volume size and extents must be specified in a way that [lvcreate(8)][lvcreate] can understand.

#### Swap Volume

- `BOOTSTRAP_USE_SWAP`: If set to a non-empty value, create a swap volume, allowing for hibernation
- `BOOTSTRAP_LVM_LV_SWAP_NAME`: The name for the swap logical volume (default: `swap`)
- `BOOTSTRAP_LVM_LV_SWAP_SIZE`: The size of the swap logical volume (default: same size as physical memory, i.e., parsed from the output of `dmidecode`, see `./bin/print-memory-size`)
- `BOOTSTRAP_FS_SWAP_LABEL`: The label for the swap file system (default: `swap`)

#### Root Volume

- `BOOTSTRAP_LVM_VG_NAME`: The volume group name (default: `sys`)
- `BOOTSTRAP_LVM_LV_ROOT_NAME`: The name for the root logical volume (default: `root`)
- `BOOTSTRAP_LVM_LV_ROOT_EXTENTS`: The extents of the root logical volume (default: `+100%FREE`)
- `BOOTSTRAP_FS_ROOT_LABEL`: The label for the root file system (default: `root`)

### Kernel

- `BOOTSTRAP_KERNEL_USE_LTS`: If set to a non-empty value, set the LTS kernel as the default
- `BOOTSTRAP_KERNEL_QUIET`: If set to a non-empty value, include `quiet` in the kernel parameters
- `BOOTSTRAP_KERNEL_LOGLEVEL`: Kernel log level (default: 4)
- `BOOTSTRAP_KERNEL_CONSOLEBLANK`: The number of seconds of inactivity to wait before putting the display to sleep (default: 0, i.e., disabled)

### Host

- `BOOTSTRAP_HOSTNAME`: The system host name (default: `arch`)
- `BOOTSTRAP_TIMEZONE`: The system time zone (default: the time zone set in the live environment, i.e., from `/etc/localtime`, or `UTC` if it's not set)

### Localization

- `BOOTSTRAP_LANG`: The default language (default: `en_US.UTF-8`)
- `BOOTSTRAP_KEYMAP`: The default keyboard mapping (default: `us`)

### Packages

- `BOOTSTRAP_PACKAGES`: Extra packages to install (multiple values should be separated with a space)
- `BOOTSTRAP_MIRROR_SORT`: The sort criteria used for mirror selection (default: `age`, choices: `age`, `rate`, `score`, or `delay`)
- `BOOTSTRAP_MIRROR_LATEST`: Only consider the n most recently synchronized mirrors (default: 5)
- `BOOTSTRAP_MIRROR_COUNTRY`: The country used for mirror selection (default: `US`, choices: see `reflector --list-countries`)

### Privileged User

- `BOOTSTRAP_ADMIN_LOGIN`: The privileged user's login (default: `admin`)
- `BOOTSTRAP_ADMIN_PASSWORD`: The privileged user's password (default: `$BOOTSTRAP_DEFAULT_PASSWORD`)
- `BOOTSTRAP_ADMIN_GROUP`: The group used to determine privileged user status (default: `wheel`)
- `BOOTSTRAP_ADMIN_GROUP_NOPASSWD`: If set to a non-empty value, users in the group will be allowed to escalate privileges without authenticating

## Testing

Installation can be tested in a virtual machine using the test script (requires `qemu-system-x86_64` and `xorriso`).

To test the default settings (only the required variables are set):

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

To automatically start the install and boot into the new system when it finishes, add the `-y` option:

```sh
./scripts/test -y /path/to/archlinux.iso
```

Once booted into the Arch Linux ISO, the current directory will have two files, `config` and `install`.

The configuration file contains all the settings that were provided to the test script and is suitable for sourcing.

The installation script contains the [basic steps](#usage) already outlined.
Output will be logged to `/root/install.log` (in addition to outputting to the virtual terminal).
When the installation is finished the log file will be copied into `$BOOTSTRAP_MOUNT_DIR/var/log`.

The bootstrap repository will be accessible in the virtual machine at `/mnt/bootstrap`.

TCP port `60022` on localhost will be forwarded to port `22` on the virtual machine.

After powering off the Arch Linux ISO, the installed system will be booted.

[btrfs-subvolumes]: https://wiki.archlinux.org/title/Btrfs#Subvolumes
[btrfs]: https://wiki.archlinux.org/title/Btrfs
[early-kms-start]: https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start
[fde]: https://wiki.archlinux.org/title/Dm-crypt
[gpt]: https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
[grub]: https://wiki.archlinux.org/title/GRUB
[install]: https://wiki.archlinux.org/title/Installation_guide
[iso]: https://archlinux.org/download/
[iwd]: https://wiki.archlinux.org/title/Iwd
[kernel]: https://wiki.archlinux.org/title/Kernel
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
