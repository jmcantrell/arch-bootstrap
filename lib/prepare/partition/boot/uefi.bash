# The size of UEFI boot partitions
# **NOTE**: The value needs to be recognizable by `sfdisk(8)`.
export BOOTSTRAP_PART_BOOT_SIZE_UEFI=${BOOTSTRAP_PART_BOOT_SIZE_UEFI:-100M}

# The type of UEFI boot partitions
export BOOTSTRAP_PART_BOOT_TYPE_UEFI=${BOOTSTRAP_PART_BOOT_TYPE_UEFI:-C12A7328-F81F-11D2-BA4B-00A0C93EC93B}
