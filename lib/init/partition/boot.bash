# The name of the boot partition
export BOOTSTRAP_PART_BOOT_NAME=${BOOTSTRAP_PART_BOOT_NAME:-boot}

source "$BOOTSTRAP_LIB_DIR"/init/partition/boot/"$BOOTSTRAP_BOOT_FIRMWARE".bash

unset part_size_default part_type_default

case $BOOTSTRAP_BOOT_FIRMWARE in
uefi)
    part_size_default=$BOOTSTRAP_PART_BOOT_SIZE_UEFI
    part_type_default=$BOOTSTRAP_PART_BOOT_TYPE_UEFI
    ;;
bios)
    part_size_default=$BOOTSTRAP_PART_BOOT_SIZE_BIOS
    part_type_default=$BOOTSTRAP_PART_BOOT_TYPE_BIOS
    ;;
esac

# The size of the boot partition (default: `$BOOTSTRAP_PART_BOOT_SIZE_<KIND>` where `<KIND>` is `UEFI` or `BIOS`)
# **NOTE**: The value needs to be recognizable by `sfdisk(8)`.
export BOOTSTRAP_PART_BOOT_SIZE=${BOOTSTRAP_PART_BOOT_SIZE:-$part_size_default}

# The type of the boot partition (default: `$BOOTSTRAP_PART_BOOT_TYPE_<KIND>` where `<KIND>` is `UEFI` or `BIOS`)
export BOOTSTRAP_PART_BOOT_TYPE=${BOOTSTRAP_PART_BOOT_TYPE:-$part_type_default}

unset part_size_default part_type_default
