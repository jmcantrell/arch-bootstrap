# The name of the system partition
export BOOTSTRAP_PART_SYS_NAME=${BOOTSTRAP_PART_SYS_NAME:-sys}

# The size of the system partition
# **NOTE**: The value needs to be recognizable by `sfdisk(8)`.
export BOOTSTRAP_PART_SYS_SIZE=${BOOTSTRAP_PART_SYS_SIZE:-+} # i.e. use all remaining space

# The type of the system partition
export BOOTSTRAP_PART_SYS_TYPE=${BOOTSTRAP_PART_SYS_TYPE:-0FC63DAF-8483-4772-8E79-3D69D8477DE4}
