# bootstrap-arch

My opinionated Arch Linux installer.

Aside from the opinions listed below, care is taken to ensure the
resulting system closely matches what you would get from following the
[official installation guide][install].

## Opinions

Boot loading is handled by GRUB with a GPT partition table using BIOS
or EFI mode, depending on the detected hardware capabilities.

Logical volume management is handled by LVM, including a swap
partition (allowing for hibernation).

If enabled, full disk encryption is handled by LUKS, using the [LVM on
LUKS][lvm-on-luks] method.

The following services are installed and enabled:

- [networkd][networkd]
- [resolved][resolved] ([mDNS enabled][mdns])
- [iwd][iwd]
- [sshd][sshd]
- [timesyncd][timesyncd]
- [reflector][reflector]
- [fstrim][ssd]

The following pacman options are changed:

- `ParallelDownloads = 5`
- `CleanMethod = KeepCurrent`

The following kernel modules are blacklisted:

- `pcspkr`

Any wireless connections created during the install will be persisted
to the installed system.

If [installing as a VirtualBox guest][vbox-guest], the guest utilities will be
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

The script `./rootfs/install` contains additional configuration
performed during the `chroot` step and is removed from the resulting
system after the installation is completed.

## Usage

In general, the installation steps are as follows:

1. Boot into a copy of the latest [Arch Linux ISO][archiso]
1. Connect to the internet
1. Copy this repository to the live environment
1. Change the directory to this repository
1. Customize the files in `./config/`
1. Prepare the environment: `. ./scripts/prepare`
1. Run the installation script: `./scripts/install`

After installation, the system is left mounted.

If all is well, `poweroff`.

### Initialize the SSH server and enable mDNS

If you want or need to manage the installation over SSH, the
`./scripts/init` script can make this easier. It does the following:

- Get a copy of this repository, if needed
- Authorize the SSH keys with access to this repository
- Enable [Multicast DNS][mdns], making `archiso.local` reachable

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

When you see the GRUB menu as the ISO is booting, press the `<tab>`
key to edit the kernel command line. Add the following:

```
script=https://gitlab.com/jmcantrell/bootstrap-arch/-/raw/main/scripts/init
```

The script will be run similarly to the curl method above as soon as
the environment is ready.

[install]: https://wiki.archlinux.org/title/Installation_guide
[lvm-on-luks]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[networkd]: https://wiki.archlinux.org/title/Systemd-networkd
[resolved]: https://wiki.archlinux.org/title/Systemd-resolved
[mdns]: https://wiki.archlinux.org/title/Systemd-resolved#mDNS
[iwd]: https://wiki.archlinux.org/title/Iwd
[sshd]: https://wiki.archlinux.org/title/OpenSSH#Server_usage
[timesyncd]: https://wiki.archlinux.org/title/Systemd-timesyncd
[reflector]: https://wiki.archlinux.org/title/Reflector
[ssd]: https://wiki.archlinux.org/title/Solid_state_drive
[vbox-guest]: https://wiki.archlinux.org/title/VirtualBox/Install_Arch_Linux_as_a_guest
[archiso]: https://archlinux.org/download/
