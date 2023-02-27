### Contains a small set of basic functionality required for loading other mods. It also handles initial setup and contains a mod_load_order.txt file for mod management.

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

### Mods will automatically disable when the game updates, so re-run the "toggle_darktide_mods.bat" script to re-enable mods after an update.

### This mod does not need to be added to your mod_load_order.txt file.