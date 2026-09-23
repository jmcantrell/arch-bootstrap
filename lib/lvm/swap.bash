# The name for the swap logical volume
export BOOTSTRAP_LVM_LV_SWAP_NAME=${BOOTSTRAP_LVM_LV_SWAP_NAME:-swap}

# The size of the swap logical volume
# **NOTE**: The value needs to be recognizable by `lvcreate(8)`.
export BOOTSTRAP_LVM_LV_SWAP_SIZE=${BOOTSTRAP_LVM_LV_SWAP_SIZE:-$BOOTSTRAP_MEMORY_SIZE}

export BOOTSTRAP_LVM_LV_SWAP_MAPPER_DEVICE=/dev/mapper/$BOOTSTRAP_LVM_VG_NAME-$BOOTSTRAP_LVM_LV_SWAP_NAME
