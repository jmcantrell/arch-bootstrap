# The kind of file system to use for the root partition/volume (choices: `ext4`, `btrfs`, or `xfs`)
export BOOTSTRAP_FS_ROOT_KIND=${BOOTSTRAP_FS_ROOT_KIND:-ext4}

case $BOOTSTRAP_FS_ROOT_KIND in
ext4 | btrfs | xfs) ;;
*)
    printf "%s: unrecognized file system: %s\n" "$0" "$BOOTSTRAP_FS_ROOT_KIND" >&2
    return 2
    ;;
esac

if [[ ! -v BOOTSTRAP_FS_ROOT_OPTIONS ]]; then
    options_file="$BOOTSTRAP_CONFIG_DIR"/file_systems/$BOOTSTRAP_FS_ROOT_KIND/options
    if [[ -f $options_file ]]; then
        BOOTSTRAP_FS_ROOT_OPTIONS=$(paste -sd, "$options_file")
        # Mount options for the root file system
        # The default value is taken from the file `./config/file_systems/$BOOTSTRAP_FS_ROOT_KIND/root/options`.
        # Multiple lines are joined together with commas.
        export BOOTSTRAP_FS_ROOT_OPTIONS
    fi
    unset options_file
fi

package_file=$BOOTSTRAP_CONFIG_DIR/packages/file_systems/$BOOTSTRAP_FS_ROOT_KIND

if [[ -f $package_file ]]; then
    export BOOTSTRAP_FS_ROOT_PACKAGE_FILE=$package_file
fi

unset package_file

# The label for the root file system
export BOOTSTRAP_FS_ROOT_LABEL=${BOOTSTRAP_FS_ROOT_LABEL:-root}

# Flag indicating that subvolumes should be used for the root file system.
# The default values are taken from the file `./config/file_systems/$BOOTSTRAP_FS_ROOT_KIND/root/subvolumes`.
# Each line must be of the form `NAME MOUNT` where `NAME` is the name of the
# subvolume and `MOUNT` is the path where the subvolume should be mounted in
# the new system.
# export BOOTSTRAP_FS_ROOT_ENABLE_SUBVOLUMES=true
