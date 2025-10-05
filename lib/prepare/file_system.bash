. ./lib/prepare/file_system/root.bash

if [[ -v BOOTSTRAP_ENABLE_SWAP ]]; then
    . ./lib/prepare/file_system/swap.bash
fi
