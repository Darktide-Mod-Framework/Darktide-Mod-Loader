# darktideML-4linux
Generic 64-bit linux build and a handy BASH script for the Darktide Mod Loader
Based on Aussiemon's original mod loader (https://github.com/Darktide-Mod-Framework/Darktide-Mod-Loader)

## Installation:
    1. Extract the mod loader files into your game folder and overwrite existing
    2. Run the provided script with `sh /path/to/<game_folder>/handle_darktide_mods.sh --enable`
    3. If the patch was successful, install the Darktide Mod Framework as normal
    4. The Darktide Mod Framework and other mods can be downloaded from
        https://www.nexusmods.com/warhammer40kdarktide

## Disabling Mods:
    * Disable individual mods by removing their name from your `mods/mod_load_order.txt`
    * Run the provided script with the `--disable` argument

## Uninstalling Mods:
    * Run the provided script with `--uninstall`
    * This will disable then delete __ALL__ modded files

## Updating the Mod Loader:
    1. Run the `--disable` command
    2. Copy the Darktide Mod Loader files to your game directory and overwrite existing
    (except for mod_load_order.txt, if you wish to preserve your mod list).
    3. Run the `--enable` command

## Updating any other Mod:
    1. Delete the mod's directory from your mods folder.
    2. Extract the updated mod to your mods folder. All settings will remain intact.


# Troubleshooting:
    * Make sure your mods have their dependencies listed above them in the load order.
    * Remove all mods from the load order (or add '--' before each line).
    * If all else fails, re-verify your game files and start the mod installation from the beginning.
    * Attempt to compile your own `dtkit-patch` as described in `tools/README.md`
    * Don't bug anyone but me with bugs. File an Issue on github or https://t.me/darktideML_4linux_SUPPORT
