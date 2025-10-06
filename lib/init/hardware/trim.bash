if [[ ! -v BOOTSTRAP_ENABLE_TRIM ]] && ! is-rotational-disk "$BOOTSTRAP_TARGET_DEVICE"; then
    # Flag indicating that TRIM is supported on the target device (default: set if the target device is not a disk with spinning platters)
    # If LUKS and/or LVM is enabled, they will be configured to issue discards.
    # The systemd service for `fstrim` will also be scheduled.
    export BOOTSTRAP_ENABLE_TRIM=true
fi
