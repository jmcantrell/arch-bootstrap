# Flag indicating that full disk encryption should be used for the target device
# export BOOTSTRAP_ENABLE_LUKS=true

# The mapper name used for the decrypted partition
export BOOTSTRAP_LUKS_MAPPER_NAME=${BOOTSTRAP_LUKS_MAPPER_NAME:-sys}

# The path of the key file on the new system used by the kernel to unlock the partition without asking for the passphrase again (slot 1, generated when added)
export BOOTSTRAP_LUKS_INITRD_KEY_FILE=${BOOTSTRAP_LUKS_INITRD_KEY_FILE:-/etc/cryptsetup-keys.d/$BOOTSTRAP_LUKS_MAPPER_NAME.key}

export BOOTSTRAP_LUKS_KEY_FILE=/tmp/bootstrap/luks/keyfile
export BOOTSTRAP_LUKS_MAPPER_DEVICE=/dev/mapper/$BOOTSTRAP_LUKS_MAPPER_NAME
