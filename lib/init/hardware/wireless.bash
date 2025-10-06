if [[ ! -v BOOTSTRAP_ENABLE_WIRELESS ]] && print-network-interfaces | grep -q '^wl'; then
    # Flag indicating that wireless networking will be used (default: set if there are any network interfaces starting with `wl`)
    export BOOTSTRAP_ENABLE_WIRELESS=true
fi
