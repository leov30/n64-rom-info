# n64-rom-info
batch scrip to get information from n64 roms
* supports .zip, or unzipped n64 roms
* needs 7zip 32bit/64bit to descompress .zip, and get crc info: https://www.7-zip.org/
* needs xxd.exe to extract hex info: https://sourceforge.net/projects/xxd-for-windows/
* will look for 7z.exe and xxd.exe in: program files, sytem32, next to script or in _bin folder
# usage

* run script inside a folder to scan .zip, and all n64 roms, or drag and drop a single file/folder or group of files to the script
* will make or update config files if surreal64 folder its found
* the script will update "output.csv" if already exist
* will output alternaive titles from all .dat files found next to the script by crc matching.


![Capture](https://user-images.githubusercontent.com/28023649/204117730-366c8409-5fe5-4cd9-8ba8-378f5e62cf76.JPG)
