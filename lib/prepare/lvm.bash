# Flag indicating that LVM should be used
# export BOOTSTRAP_ENABLE_LVM=true

# The name for the system volume group
export BOOTSTRAP_LVM_VG_NAME=${BOOTSTRAP_LVM_VG_NAME:-sys}

source "$BOOTSTRAP_LIB_DIR"/prepare/lvm/root.bash

if [[ -v BOOTSTRAP_ENABLE_SWAP ]]; then
    source "$BOOTSTRAP_LIB_DIR"/prepare/lvm/swap.bash
fi
