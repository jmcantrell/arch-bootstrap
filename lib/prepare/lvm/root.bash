# The name for the root logical volume
export BOOTSTRAP_LVM_LV_ROOT_NAME=${BOOTSTRAP_LVM_LV_ROOT_NAME:-root}

# The extents of the root logical volume
# **NOTE**: The value needs to be recognizable by `lvcreate(8)`.
export BOOTSTRAP_LVM_LV_ROOT_EXTENTS=${BOOTSTRAP_LVM_LV_ROOT_EXTENTS:-+100%FREE} # i.e. use all remaining space

export BOOTSTRAP_LVM_LV_ROOT_MAPPER_DEVICE=/dev/$BOOTSTRAP_LVM_VG_NAME/$BOOTSTRAP_LVM_LV_ROOT_NAME
