# The size of BIOS boot partitions
# **NOTE**: The value needs to be recognizable by `sfdisk(8)`.
export BOOTSTRAP_PART_BOOT_SIZE_BIOS=${BOOTSTRAP_PART_BOOT_SIZE_BIOS:-1M}

# The type of BIOS boot partitions
export BOOTSTRAP_PART_BOOT_TYPE_BIOS=${BOOTSTRAP_PART_BOOT_TYPE_BIOS:-21686148-6449-6E6F-744E-656564454649}
