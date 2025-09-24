if [[ ! -v BOOTSTRAP_GPU_MODULES ]]; then
    if ! gpu_modules=$(gpu-modules | paste -sd' '); then
        printf "unable to get gpu kernel modules\n" >&2
        return 1
    fi
    export BOOTSTRAP_GPU_MODULES=$gpu_modules
fi
