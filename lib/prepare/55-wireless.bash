if [[ ! -v BOOTSTRAP_USE_WIRELESS ]] && network-interfaces | grep -q '^wl'; then
    export BOOTSTRAP_USE_WIRELESS=1
fi
