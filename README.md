# n64-rom-info
batch scrip to get information from n64 roms
needs 7z zip installed, or 7z.exe command line version in _bin folder
needs xxd.exe in _bin folder to extract hex info https://sourceforge.net/projects/xxd-for-windows/ 

# usage
just drag and drop .zip n64 compressed ROM, or a .z64, .bin file
will also batch process a folder with roms if a folder its draged and doroped

will give internal rom name
crc1, crc2, country code, and country description, project64 format
will calculate swaped crc for rice plugin
internal version, size(zip), crc(zip), media type.
will generate a spreadsheet for folder, and output.txt with single file info 
