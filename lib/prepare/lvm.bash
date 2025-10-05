# Flag indicating that LVM should be used
# export BOOTSTRAP_ENABLE_LVM=true

# The name for the system volume group
export BOOTSTRAP_LVM_VG_NAME=${BOOTSTRAP_LVM_VG_NAME:-sys}

. ./lib/prepare/lvm/root.bash

if [[ -v BOOTSTRAP_ENABLE_SWAP ]]; then
    . ./lib/prepare/lvm/swap.bash
fi
