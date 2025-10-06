# arch-bootstrap

An opinionated Arch Linux installer.

The target system should closely match the result of following the [official installation guide][install].

## Opinions

Components used:

- [GPT][gpt] partition table
- [GRUB][grub] boot loader ([UEFI][grub-uefi] or [BIOS][grub-bios])
- [LVM][lvm] volume management ([optional](#bootstrap_enable_lvm))
- [LUKS][luks] full disk encryption ([optional](#bootstrap_enable_luks))
- [Dedicated swap partition/volume][swap-partition], allowing for [hibernation][hibernation] ([optional](#bootstrap_enable_swap))
- [Processor microcode updates][microcode] for the [CPU vendor](#bootstrap_cpu_vendor)
- [Early KMS start][early-kms-start] for any [graphics chip sets](#bootstrap_gpu_modules)

Enabled systemd units:

- [systemd-networkd].service (with [Multicast DNS][mdns] enabled)
- [systemd-resolved].service (with `stub-resolv.conf`)
- [systemd-timesyncd].service
- [reflector].{service,timer}
- [sshd].service
- [fstrim][ssd-trim].timer (if trim is [enabled](#bootstrap_enable_trim))
- [iwd].service (if wireless networking is [enabled](#bootstrap_enable_wireless))

Additional configuration:

- If [wireless networking is enabled](#bootstrap_enable_wireless), any [networks][iwd-networks] on the live system will be persisted.
- If [trim is enabled](#bootstrap_enable_trim), discards will be configured in [LVM][lvm-thin] and [LUKS][luks-trim].
- A [privileged user](#bootstrap_admin_group) will be created and the root account will be locked.
- If using both LVM and LUKS, the [LVM on LUKS][lvm-on-luks] method will be used.
- Any SSH public keys authorized on the live system will be persisted.

See [configuration](#configuration) for complete details on customizing the installation.

## Usage

Boot into the [live environment][iso] and change the directory to this repository.

Set [environment variables](#configuration) to configure installation:

```sh
export BOOTSTRAP_TARGET_DEVICE=/dev/sda
export BOOTSTRAP_ADMIN_LOGIN=bob
export BOOTSTRAP_MIRROR_SORT=rate
export BOOTSTRAP_TIMEZONE=America/Chicago
export BOOTSTRAP_ENABLE_LUKS=1
```

Initialize the environment on the live system:

```sh
source ./init
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

Transfer the repository to the live system and assign it to [`BOOTSTRAP_PACKAGE_REPO_DIR`](#bootstrap_package_repo_dir).
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
- Set the host name of the live system to [`$BOOTSTRAP_HOSTNAME`](#bootstrap_hostname) (if the environment variable is set)
- Try to mount a drive with the label `BOOTSTRAP` at `/mnt/bootstrap`
- Try to mount a drive with the label `PACKAGES` at `/mnt/packages`
- Add configuration to the file `/root/config` on the live system
- Create an installation entry point script at `/root/install` on the live system that logs its output to `/root/install.log` and `/var/log/install.log` on the target system

To see complete usage details:

```sh
./scripts/mkci --help
```

### Virtual Machine Installation

The script `./scripts/mkvm` can be used to bootstrap a virtual machine (requires `qemu`, `xorriso`, `jo`, and `yq`).

The virtual machine will be booted with a cloud-init image generated using the [script described earlier](#automated-installation).

Additionally, it will do the following:

- Mount `$PWD` on the host system at `/mnt/bootstrap` on the live system
- Mount `/var/cache/bootstrap/repo` on the host system at `/mnt/packages` on the live system 
- Configure [offline installation](#offline-installation) for `/mnt/packages`
- Forward TCP port `60022` on the host system to port `22` on the virtual machine
- Allow SSH connections over vsock at client id `42`

To create a virtual machine with the default settings (only the installation disk set):

```sh
./scripts/mkvm /path/to/archlinux.iso /path/to/disk.cow
```

To add certain settings, export them before running the script:

```sh
export BOOTSTRAP_HOSTNAME=vm
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

If you already have access to the repository in the live system, run the script normally to authorize the keys and enable mDNS:

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
export BOOTSTRAP_TIMEZONE=America/Chicago
export BOOTSTRAP_ADMIN_LOGIN=frank

./scripts/test /path/to/archlinux.iso
```

To see complete usage details:

```sh
./scripts/test --help
```

## Configuration

The details of the system being installed are controlled entirely by environment variables.

There's only one required variable, [`BOOTSTRAP_TARGET_DEVICE`](#bootstrap_target_device).
It must be explicitly set because it's so destructive.

Any of the following variables that are needed should be defined and exported before sourcing the initialization script (`./init`).

<!-- CONFIG START -->

### `BOOTSTRAP_ADMIN_GROUP`

<!-- ./lib/prepare/chroot/admin.bash -->

The group used to determine privileged user status (default: `wheel`)

### `BOOTSTRAP_ADMIN_LOGIN`

<!-- ./lib/prepare/chroot/admin.bash -->

The privileged user's login (default: `admin`)

### `BOOTSTRAP_BOOT_FIRMWARE`

<!-- ./lib/prepare/hardware/boot_firmware.bash -->

The boot firmware interface (default: `uefi` if `/sys/firmware/efi/efivars` exists, otherwise `bios`)

### `BOOTSTRAP_CPU_VENDOR`

<!-- ./lib/prepare/hardware/cpu.bash -->

The vendor of the system's CPU (choices: `intel` or `amd`, default: parsed from `vendor_id` in `/proc/cpuinfo`)

### `BOOTSTRAP_ENABLE_LUKS`

<!-- ./lib/prepare/luks.bash -->

Flag indicating that full disk encryption should be used for the target device (e.g. `true`)

### `BOOTSTRAP_ENABLE_LVM`

<!-- ./lib/prepare/lvm.bash -->

Flag indicating that LVM should be used (e.g. `true`)

### `BOOTSTRAP_ENABLE_SWAP`

<!-- ./lib/prepare/swap.bash -->

Flag indicating that a dedicated area for swap should be used (e.g. `true`)

When LVM is enabled, a logical volume is used instead of a partition.

### `BOOTSTRAP_ENABLE_TRIM`

<!-- ./lib/prepare/hardware/trim.bash -->

Flag indicating that TRIM is supported on the target device (default: set if the target device is not a disk with spinning platters)

If LUKS and/or LVM is enabled, they will be configured to issue discards.
The systemd service for `fstrim` will also be scheduled.

### `BOOTSTRAP_ENABLE_WIRELESS`

<!-- ./lib/prepare/hardware/wireless.bash -->

Flag indicating that wireless networking will be used (default: set if there are any network interfaces starting with `wl`)

### `BOOTSTRAP_FONT`

<!-- ./lib/prepare/chroot/console.bash -->

The default console font

### `BOOTSTRAP_FONT_MAP`

<!-- ./lib/prepare/chroot/console.bash -->

The default console font map

### `BOOTSTRAP_FONT_UNIMAP`

<!-- ./lib/prepare/chroot/console.bash -->

The default console unicode font map

### `BOOTSTRAP_FS_ROOT_ENABLE_SUBVOLUMES`

<!-- ./lib/prepare/file_system/root.bash -->

Flag indicating that subvolumes should be used for the root file system (e.g. `true`).

The default values are taken from the file `./config/file_system/$BOOTSTRAP_FS_ROOT_KIND/root/subvolumes`.
Each line must be of the form `NAME MOUNT` where `NAME` is the name of the
subvolume and `MOUNT` is the path where the subvolume should be mounted in
the new system.

### `BOOTSTRAP_FS_ROOT_KIND`

<!-- ./lib/prepare/file_system/root.bash -->

The kind of file system to use for the root partition/volume (choices: `ext4`, `btrfs`, or `xfs`, default: `ext4`)

### `BOOTSTRAP_FS_ROOT_LABEL`

<!-- ./lib/prepare/file_system/root.bash -->

The label for the root file system (default: `root`)

### `BOOTSTRAP_FS_ROOT_OPTIONS`

<!-- ./lib/prepare/file_system/root.bash -->

Mount options for the root file system

The default value is taken from the file `./config/file_system/$BOOTSTRAP_FS_ROOT_KIND/root/options`.
Multiple lines are joined together with commas.

### `BOOTSTRAP_FS_SWAP_LABEL`

<!-- ./lib/prepare/file_system/swap.bash -->

The label for the swap file system (default: `swap`)

### `BOOTSTRAP_GPU_MODULES`

<!-- ./lib/prepare/hardware/gpu.bash -->

The kernel modules used by the system's GPUs (default: parsed from the output of `lspci -k`, e.g. `i915 xe`)

Multiple values should be separated with a space.

### `BOOTSTRAP_HOSTNAME`

<!-- ./lib/prepare/chroot/hostname.bash -->

The system host name (e.g. `arch`)

### `BOOTSTRAP_KERNEL_CONSOLEBLANK`

<!-- ./lib/prepare/chroot/kernel.bash -->

The number of seconds of inactivity to wait before putting the display to sleep (e.g. `$((10 * 60))`)

### `BOOTSTRAP_KERNEL_LOGLEVEL`

<!-- ./lib/prepare/chroot/kernel.bash -->

Kernel log level (e.g. `4`)

### `BOOTSTRAP_KERNEL_QUIET`

<!-- ./lib/prepare/chroot/kernel.bash -->

If set to a non-empty value, include `quiet` in the kernel parameters (e.g. `true`)

### `BOOTSTRAP_KERNEL_USE_LTS`

<!-- ./lib/prepare/chroot/kernel.bash -->

Flag indicating that the LTS kernel should be used by default (e.g. `true`)

### `BOOTSTRAP_KEYMAP`

<!-- ./lib/prepare/chroot/console.bash -->

The default keyboard mapping (e.g. `us`)

### `BOOTSTRAP_KEYMAP_TOGGLE`

<!-- ./lib/prepare/chroot/console.bash -->

The default secondary keyboard mapping

### `BOOTSTRAP_LANG`

<!-- ./lib/prepare/chroot/locale.bash -->

The default language (default: `C.UTF-8`)

### `BOOTSTRAP_LANGUAGE`

<!-- ./lib/prepare/chroot/locale.bash -->

The default language priority list

Multiple should be separated with a colon.

### `BOOTSTRAP_LC_ADDRESS`

<!-- ./lib/prepare/chroot/locale.bash -->

The default format for locations

### `BOOTSTRAP_LC_COLLATE`

<!-- ./lib/prepare/chroot/locale.bash -->

The default format for sorting and regular expressions

### `BOOTSTRAP_LC_CTYPE`

<!-- ./lib/prepare/chroot/locale.bash -->

The default interpretation of byte sequences as characters

### `BOOTSTRAP_LC_IDENTIFICATION`

<!-- ./lib/prepare/chroot/locale.bash -->

The default settings for locale metadata

### `BOOTSTRAP_LC_MEASUREMENT`

<!-- ./lib/prepare/chroot/locale.bash -->

The default settings related to the measurement system

### `BOOTSTRAP_LC_MESSAGES`

<!-- ./lib/prepare/chroot/locale.bash -->

The default language for messages

### `BOOTSTRAP_LC_MONETARY`

<!-- ./lib/prepare/chroot/locale.bash -->

The default formatting for monetary-related numeric values

### `BOOTSTRAP_LC_NAME`

<!-- ./lib/prepare/chroot/locale.bash -->

The default format used to address persons

### `BOOTSTRAP_LC_NUMERIC`

<!-- ./lib/prepare/chroot/locale.bash -->

The default formatting rules for non-monetary numeric values

### `BOOTSTRAP_LC_PAPER`

<!-- ./lib/prepare/chroot/locale.bash -->

The default settings related to the dimensions of the standard paper size

### `BOOTSTRAP_LC_TELEPHONE`

<!-- ./lib/prepare/chroot/locale.bash -->

The default settings that describe the formats for telephone services

### `BOOTSTRAP_LC_TIME`

<!-- ./lib/prepare/chroot/locale.bash -->

The default formatting for date and time values

### `BOOTSTRAP_LUKS_INITRD_KEY_FILE`

<!-- ./lib/prepare/luks.bash -->

The path of the key file on the new system used by the kernel to unlock the partition without asking for the passphrase again (slot 1, generated when added, default: `/etc/cryptsetup-keys.d/$BOOTSTRAP_LUKS_MAPPER_NAME.key`)

### `BOOTSTRAP_LUKS_MAPPER_NAME`

<!-- ./lib/prepare/luks.bash -->

The mapper name used for the decrypted partition (default: `sys`)

### `BOOTSTRAP_LVM_LV_ROOT_EXTENTS`

<!-- ./lib/prepare/lvm/root.bash -->

The extents of the root logical volume (default: `+100%FREE`, i.e. use all remaining space)

**NOTE**: The value needs to be recognizable by [`lvcreate(8)`](https://man.archlinux.org/man/lvcreate.8).

### `BOOTSTRAP_LVM_LV_ROOT_NAME`

<!-- ./lib/prepare/lvm/root.bash -->

The name for the root logical volume (default: `root`)

### `BOOTSTRAP_LVM_LV_SWAP_NAME`

<!-- ./lib/prepare/lvm/swap.bash -->

The name for the swap logical volume (default: `swap`)

### `BOOTSTRAP_LVM_LV_SWAP_SIZE`

<!-- ./lib/prepare/lvm/swap.bash -->

The size of the swap logical volume (default: `$BOOTSTRAP_MEMORY_SIZE`)

**NOTE**: The value needs to be recognizable by [`lvcreate(8)`](https://man.archlinux.org/man/lvcreate.8).

### `BOOTSTRAP_LVM_VG_NAME`

<!-- ./lib/prepare/lvm.bash -->

The name for the system volume group (default: `sys`)

### `BOOTSTRAP_MEMORY_SIZE`

<!-- ./lib/prepare/hardware/memory.bash -->

The amount of memory available (parsed from the output of `dmidecode`, default: same as ram size)

### `BOOTSTRAP_MIRROR_COUNTRY`

<!-- ./lib/prepare/chroot/mirrors.bash -->

The country used for mirror selection (default: `US`)

See `reflector --list-countries` for possible values.

### `BOOTSTRAP_MIRROR_LATEST`

<!-- ./lib/prepare/chroot/mirrors.bash -->

The maximum number of the most recently synchronized mirrors (default: `5`)

### `BOOTSTRAP_MIRROR_SORT`

<!-- ./lib/prepare/chroot/mirrors.bash -->

The sort criteria used for mirror selection (default: `age`)

See `reflector --help` for possible values.

### `BOOTSTRAP_PACKAGE_REPO_DIR`

<!-- ./lib/prepare/chroot/mirrors.bash -->

Look for packages in this offline package repository directory (e.g. `/mnt/packages`)

### `BOOTSTRAP_PART_BOOT_NAME`

<!-- ./lib/prepare/partition/boot.bash -->

The name of the boot partition (default: `boot`)

### `BOOTSTRAP_PART_BOOT_SIZE`

<!-- ./lib/prepare/partition/boot.bash -->

The size of the boot partition (default: `$BOOTSTRAP_PART_BOOT_SIZE_<KIND>` where `<KIND>` is `UEFI` or `BIOS`)

### `BOOTSTRAP_PART_BOOT_SIZE_BIOS`

<!-- ./lib/prepare/partition/boot/bios.bash -->

The size of BIOS boot partitions (default: `1M`)

**NOTE**: The value needs to be recognizable by [`sfdisk(8)`](https://man.archlinux.org/man/sfdisk.8).

### `BOOTSTRAP_PART_BOOT_SIZE_UEFI`

<!-- ./lib/prepare/partition/boot/uefi.bash -->

The size of UEFI boot partitions (default: `100M`)

**NOTE**: The value needs to be recognizable by [`sfdisk(8)`](https://man.archlinux.org/man/sfdisk.8).

### `BOOTSTRAP_PART_BOOT_TYPE`

<!-- ./lib/prepare/partition/boot.bash -->

The type of the boot partition (default: `$BOOTSTRAP_PART_BOOT_TYPE_<KIND>` where `<KIND>` is `UEFI` or `BIOS`)

### `BOOTSTRAP_PART_BOOT_TYPE_BIOS`

<!-- ./lib/prepare/partition/boot/bios.bash -->

The type of BIOS boot partitions (default: `21686148-6449-6E6F-744E-656564454649`)

### `BOOTSTRAP_PART_BOOT_TYPE_UEFI`

<!-- ./lib/prepare/partition/boot/uefi.bash -->

The type of UEFI boot partitions (default: `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`)

### `BOOTSTRAP_PART_SWAP_NAME`

<!-- ./lib/prepare/partition/swap.bash -->

The name of the swap partition (default: `swap`)

### `BOOTSTRAP_PART_SWAP_SIZE`

<!-- ./lib/prepare/partition/swap.bash -->

The size of the swap partition (default: `$BOOTSTRAP_MEMORY_SIZE`)

**NOTE**: The value needs to be recognizable by [`sfdisk(8)`](https://man.archlinux.org/man/sfdisk.8).

### `BOOTSTRAP_PART_SWAP_TYPE`

<!-- ./lib/prepare/partition/swap.bash -->

The type of the swap partition (default: `0657FD6D-A4AB-43C4-84E5-0933C84B4F4F`)

### `BOOTSTRAP_PART_SYS_NAME`

<!-- ./lib/prepare/partition/sys.bash -->

The name of the system partition (default: `sys`)

### `BOOTSTRAP_PART_SYS_SIZE`

<!-- ./lib/prepare/partition/sys.bash -->

The size of the system partition (default: `+`, i.e. use all remaining space)

**NOTE**: The value needs to be recognizable by [`sfdisk(8)`](https://man.archlinux.org/man/sfdisk.8).

### `BOOTSTRAP_PART_SYS_TYPE`

<!-- ./lib/prepare/partition/sys.bash -->

The type of the system partition (default: `0FC63DAF-8483-4772-8E79-3D69D8477DE4`)

### `BOOTSTRAP_TARGET_DEVICE`

<!-- ./lib/prepare/target.bash -->

The disk that will contain the new system (**WARNING**: all existing data will be destroyed without confirmation, e.g. `/path/to/device`)

### `BOOTSTRAP_TARGET_MOUNT_DIR`

<!-- ./lib/prepare/target.bash -->

The path where the new system will be mounted during installation (default: `/mnt/target`)

### `BOOTSTRAP_TIMEZONE`

<!-- ./lib/prepare/chroot/timezone.bash -->

The system time zone (default: the time zone in the live environment, if set)

### `BOOTSTRAP_UEFI_MOUNT_DIR`

<!-- ./lib/prepare/hardware/boot_firmware.bash -->

The path where the EFI partition will be mounted on the new system (if applicable, default: `/efi`)

<!-- CONFIG END -->

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
[luks-trim]: https://wiki.archlinux.org/title/Dm-crypt/Specialties#Discard/TRIM_support_for_solid_state_drives_(SSD)
[luks]: https://wiki.archlinux.org/title/Dm-crypt
[lvm-on-luks]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[lvm-thin]: https://wiki.archlinux.org/title/LVM#Thin_provisioning
[lvm]: https://wiki.archlinux.org/title/LVM
[mdns]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[microcode]: https://wiki.archlinux.org/title/Microcode
[offline-install]: https://wiki.archlinux.org/title/Offline_installation
[reflector]: https://wiki.archlinux.org/title/Reflector
[ssd-trim]: https://wiki.archlinux.org/title/Solid_state_drive#TRIM
[sshd]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[swap-partition]: https://wiki.archlinux.org/title/Swap#Swap_partition
[systemd-networkd]: https://wiki.archlinux.org/title/Systemd-networkd
[systemd-resolved]: https://wiki.archlinux.org/title/Systemd-resolved
[systemd-timesyncd]: https://wiki.archlinux.org/title/Systemd-timesyncd
