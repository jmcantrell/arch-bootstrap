if [[ ! -v BOOTSTRAP_GPU_MODULES ]]; then
    if ! reply=$(print-gpu-modules | paste -sd' '); then
        printf "unable to get gpu kernel modules\n" >&2
        return 1
    fi
    # The kernel modules used by the system's GPUs (default: parsed from the output of `lspci -k`, e.g. `i915 xe`)
    # Multiple values should be separated with a space.
    export BOOTSTRAP_GPU_MODULES=$reply
    unset reply
fi
