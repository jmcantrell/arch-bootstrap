# The name of the swap partition
export BOOTSTRAP_PART_SWAP_NAME=${BOOTSTRAP_PART_SWAP_NAME:-swap}

# The size of the swap partition
# **NOTE**: The value needs to be recognizable by `sfdisk(8)`.
export BOOTSTRAP_PART_SWAP_SIZE=${BOOTSTRAP_PART_SWAP_SIZE:-$BOOTSTRAP_MEMORY_SIZE}

# The type of the swap partition
export BOOTSTRAP_PART_SWAP_TYPE=${BOOTSTRAP_PART_SWAP_TYPE:-0657FD6D-A4AB-43C4-84E5-0933C84B4F4F}
