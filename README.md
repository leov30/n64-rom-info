# n64-rom-info
batch scrip to get information from n64 roms
* supports .zip, or unzipped n64 roms
* needs 7z zip installed 32bit/64bit to descompress .zip, and get crc info: https://www.7-zip.org/
* needs xxd.exe in _bin folder to extract hex info: https://sourceforge.net/projects/xxd-for-windows/
* will look for 7z.exe and xxd.exe, program files, next to script, _bin folder or in system32 folder


# usage

* run script inside a folder to scan .zip, and all n64 roms, or drag and drop a single file/folder or group of files to the script
* will make or update config files if surreal64 folder its found
* the script will update "output.csv" if already exist


![Capture](https://user-images.githubusercontent.com/28023649/204107080-f101497a-5c64-4986-ba7f-54a2209b1933.JPG)
