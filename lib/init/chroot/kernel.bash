# Flag indicating that the LTS kernel should be used by default
# export BOOTSTRAP_KERNEL_USE_LTS=true

export BOOTSTRAP_KERNEL_TOP_LEVEL=/boot/vmlinuz-linux${BOOTSTRAP_KERNEL_USE_LTS:+-lts}

# Extra boot parameters (e.g. `quiet loglevel=4 consoleblank=600`).
export BOOTSTRAP_KERNEL_PARAMETERS=${BOOTSTRAP_KERNEL_PARAMETERS:-}
