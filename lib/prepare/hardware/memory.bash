if [[ ! -v BOOTSTRAP_MEMORY_SIZE ]]; then
    if reply=$(print-memory-size); then
        # The amount of memory available (parsed from the output of `dmidecode`, default: same as ram size)
        export BOOTSTRAP_MEMORY_SIZE=$reply
    fi
    unset reply
fi
