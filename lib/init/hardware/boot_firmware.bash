if [[ ! -v BOOTSTRAP_BOOT_FIRMWARE ]]; then
    if [[ -d /sys/firmware/efi/efivars ]]; then
        boot_firmware=uefi
    else
        boot_firmware=bios
    fi
    # The boot firmware interface (default: `uefi` if `/sys/firmware/efi/efivars` exists, otherwise `bios`)
    export BOOTSTRAP_BOOT_FIRMWARE=$boot_firmware
    unset boot_firmware
fi

if [[ $BOOTSTRAP_BOOT_FIRMWARE == uefi ]]; then
    # The path where the EFI partition will be mounted on the new system (if applicable)
    export BOOTSTRAP_UEFI_MOUNT_DIR=${BOOTSTRAP_UEFI_MOUNT_DIR:-/efi}
fi

package_file=$BOOTSTRAP_CONFIG_DIR/packages/boot/$BOOTSTRAP_BOOT_FIRMWARE

if [[ ! -f $package_file ]]; then
    printf "%s: invalid boot firmware: %s\n" "$0" "$BOOTSTRAP_BOOT_FIRMWARE" >&2
    return 2
fi

export BOOTSTRAP_BOOT_FIRMWARE_PACKAGE_FILE=$package_file
unset package_file
