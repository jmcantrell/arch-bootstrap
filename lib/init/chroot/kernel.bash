# Flag indicating that the LTS kernel should be used by default
# export BOOTSTRAP_KERNEL_USE_LTS=true

export BOOTSTRAP_KERNEL_TOP_LEVEL=/boot/vmlinuz-linux${BOOTSTRAP_KERNEL_USE_LTS:+-lts}

# If set to a non-empty value, include `quiet` in the kernel parameters
# export BOOTSTRAP_KERNEL_QUIET=true

# Kernel log level
# export BOOTSTRAP_KERNEL_LOGLEVEL=4

# The number of seconds of inactivity to wait before putting the display to sleep
# export BOOTSTRAP_KERNEL_CONSOLEBLANK=$((10 * 60))
