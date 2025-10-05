part_prefix=$BOOTSTRAP_TARGET_DEVICE

if [[ ${BOOTSTRAP_TARGET_DEVICE##*/} == nvme* ]]; then
    part_prefix+=p
fi

source "$BOOTSTRAP_LIB_DIR"/prepare/partition/boot.bash

export BOOTSTRAP_PART_BOOT_DEVICE=${part_prefix}1

source "$BOOTSTRAP_LIB_DIR"/prepare/partition/sys.bash

if [[ -v BOOTSTRAP_ENABLE_SWAP && ! -v BOOTSTRAP_ENABLE_LVM ]]; then
    source "$BOOTSTRAP_LIB_DIR"/prepare/partition/swap.bash
    export BOOTSTRAP_PART_SWAP_DEVICE=${part_prefix}2
    export BOOTSTRAP_PART_SYS_DEVICE=${part_prefix}3
else
    export BOOTSTRAP_PART_SYS_DEVICE=${part_prefix}2
fi

unset part_prefix
