# n64-rom-info
batch scrip to get information from n64 roms
* supports .zip, or unzipped n64 roms
* needs 7zip 32bit/64bit to descompress .zip, and get crc info: https://www.7-zip.org/
* needs xxd.exe to extract hex info: https://sourceforge.net/projects/xxd-for-windows/
* will look for 7z.exe and xxd.exe in: program files, sytem32, next to script or in _bin folder
# usage

* run script inside a folder to scan .zip, and all n64 roms, or drag and drop a single file/folder or group of files to the script
* will make or update config files if surreal64 folder its found (will not add duplicated entries)
* the script will update "output.csv" if already exist (will not add duplicated entries)
* will output alternaive title if a .dat file its found next to the script

![Capture](https://user-images.githubusercontent.com/28023649/204120142-0f0078a2-6e5a-4327-a810-024406cabe86.JPG)

# ogxbox surreal64
* normal mode:
drag and drop .zip, unzipped, a folder or just run the script and will extract rom information, and build a spreadsheet

* surreal64 updater mode:
make a folder called "surreal64" and will add the rom info to the emulator configuration files, or will build new ones

* surreal64.ini mode:
drag and drop "surreal.ini" to the script and a new menu will appear
- rename .png to surreal.ini alt. name, game name, CRC1
- add permanent config to surreal.ini using a saves folder
- create saves folder configuration files from EWJ game name/comments in sureal.ini
- rename zip roms to alt name or game name from surreal.ini, also rename to ROM crc or header crc

* zelda patcher mode:
make folder called "patch_ocarina" and "patch_mask" and the script will rename the header of the ROMs to LEGEND OF ZELDA or MAJORAS MASK, this is to activate the HUD and heart fix for zelda hacks in 6.0b




