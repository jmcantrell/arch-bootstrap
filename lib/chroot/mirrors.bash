# The sort criteria used for mirror selection
# See `reflector --help` for possible values.
export BOOTSTRAP_MIRROR_SORT=${BOOTSTRAP_MIRROR_SORT:-age}

# The maximum number of the most recently synchronized mirrors
export BOOTSTRAP_MIRROR_LATEST=${BOOTSTRAP_MIRROR_LATEST:-5}

# The country used for mirror selection
# See `reflector --list-countries` for possible values.
export BOOTSTRAP_MIRROR_COUNTRY=${BOOTSTRAP_MIRROR_COUNTRY:-US}
