### Contains a small set of basic functionality required for loading other mods. It also handles initial setup and contains a mod_load_order.txt file for mod management.

### Game updates will automatically disable all mods. Re-run "toggle_darktide_mods.bat" to enable them again.

### This mod does not need to be added to your mod_load_order.txt file.

## Installation:
    1. Copy the Darktide Mod Loader files to your game directory and overwrite existing.
    2. Run the "toggle_darktide_mods.bat" script in your game folder.
    3. Copy the Darktide Mod Framework files to your "mods" directory (<game folder>/mods) and overwrite existing.
    3. Install other mods by downloading them from the Nexus site (https://www.nexusmods.com/warhammer40kdarktide) then adding them to "<game folder>/mods/mod_load_order.txt" with a text editor.
    
## Disable mods:
    * Disable individual mods by removing their name from your mods/mod_load_order.txt file.
    * Run the "toggle_darktide_mods.bat" script at your game folder and choose to unpatch the bundle database to disable all mod loading.
    
## Uninstallation:
    1. Run the "toggle_darktide_mods.bat" script at your game folder and choose to unpatch the bundle database.
    2. Delete the mods and tools folders from your game directory.
    3. Delete the "mod_loader" file from <game folder>/binaries.
    4. Delete the "9ba626afa44a3aa3.patch_999" file from <game folder>/bundle.

## Updating the mod loader:
    1. Run the "toggle_darktide_mods.bat" script at your game folder and choose to unpatch the bundle database.
    2. Copy the Darktide Mod Loader files to your game directory and overwrite existing (except for mod_load_order.txt, if you wish to preserve your mod list).
    3. Run "toggle_darktide_mods.bat" at your game folder to re-enable mods.

## Updating any other mod:
    1. Delete the mod's directory from your mods folder.
    2. Extract the updated mod to your mods folder. All settings will remain intact.

## Troubleshooting:
    * Make sure your game folder, mods folder, and mod_load_order.txt look like the images on this page: <https://www.nexusmods.com/warhammer40kdarktide/mods/19>
    * Make sure your mods have their dependencies listed above them in the load order.
    * Remove all mods from the load order (or add '--' before each line).
    * If all else fails, re-verify your game files and start the mod installation from the beginning.

## Creating mods:
    1. Download the latest Darktide Mod Builder release: <https://github.com/Darktide-Mod-Framework/Darktide-Mod-Builder/releases>.
    2. Add the unzipped folder to your environment path: <https://www.computerhope.com/issues/ch000549.htm>.
    3. Run create_mod.bat or "dmb create <mod name>" in the mods folder. This generates a mod folder with the same name.
    4. Add the new mod name to your mod_load_order.txt.
    5. Reload mods or restart the game.
