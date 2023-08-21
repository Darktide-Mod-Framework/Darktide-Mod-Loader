
# This script is used to enable, disable, and uninstall mods

# displays usage information
function help_user {
    echo Please execute this script with one of the following options:
    echo "  --enable"
    echo "  --disable"
    echo "  --uninstall"
}

# patches game files to enable mods
function enable_mods {
    echo enabling mods...
    ./tools/dtkit-patch --patch ./bundle
}

# disables the mod patch
function disable_mods {
    echo disabling mods...
    ./tools/dtkit-patch --unpatch ./bundle
}

# disables the mod patch and delete all extraneous files
function uninstall_mods {
    disable_mods
    echo deleting files...
    rm -R mods
    rm -R tools
    rm binaries/mod_loader
    rm bundle/9ba626afa44a3aa3.patch_999
    rm README.md
    rm handle_darktide_mods.sh
    echo done
}



### MAIN #
if [ -z "$1" ]; then
    echo No option selected!
    help_user
elif [ $1 == "--enable" ]; then
    enable_mods
elif [ $1 == "--disable" ]; then
    disable_mods
elif [ $1 == "--uninstall" ]; then
    uninstall_mods
else
    echo Option not recognized!
    help_user
fi
### MAIN #
