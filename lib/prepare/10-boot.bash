if [[ ! -v BOOTSTRAP_BOOT_FIRMWARE ]]; then
    if [[ -d /sys/firmware/efi/efivars ]]; then
        export BOOTSTRAP_BOOT_FIRMWARE=uefi
    else
        export BOOTSTRAP_BOOT_FIRMWARE=bios
    fi
fi

boot_firmware_package_file=$BOOTSTRAP_CONFIG_DIR/packages/boot/$BOOTSTRAP_BOOT_FIRMWARE
if [[ ! -f $boot_firmware_package_file ]]; then
    printf "%s: invalid boot firmware: %s\n" "$0" "$BOOTSTRAP_BOOT_FIRMWARE" >&2
    return 2
fi
export BOOTSTRAP_BOOT_FIRMWARE_PACKAGE_FILE=$boot_firmware_package_file
