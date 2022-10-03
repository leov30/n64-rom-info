@echo off

if "%~1"=="" echo. only drag and drop files, or folder&pause&exit
if not exist "%~1" echo. error, change path or name of the file&pause&exit



set "_path=%~dp0"
set "_path=%_path:~0,-1%"

if not exist "%_path%\_bin" MD "%_path%\_bin"

if not exist "%_path%\_bin\xxd.exe" (
	title ERROR
	echo THIS SCRIPT NEEDS xxd.exe in _bin
	pause & exit
)

REM //use alternative
if not exist "%programfiles%\7-Zip\7z.exe" (
	if not exist "%_path%\_bin\7z.exe" (
		title ERROR
		echo THIS SCRIPT NEEDS 7zip to be installed or 7z.exe in _bin folder 
		pause & exit
	)else (
		set "_7zip=%_path%\_bin\7z.exe"
	)
)else (
	set "_7zip=%programfiles%\7-Zip\7z.exe"
)


set "_folder=%~n1\"



REM ****** line counter ************
set /a "_total_lines=0"
set /a "_count_lines=0"

if not exist _temp md _temp

REM //test if its a file or folder
if not exist "%_folder%" (
	
	set /a "_total_lines=1"
	set "_folder="
	if "%~x1"==".zip" call :ext_zipinfo "%~n1.zip"
	if "%~x1"==".z64" call :ext_zipinfo "%~n1.z64"
	if "%~x1"==".bin" call :ext_zipinfo "%~n1.bin"
	REM //esle not compatible format
	
	move /y output.txt "%_path%"
	del _temp\temp.1 & rd _temp
	pause & exit
	
)

REM //spreadsheet headers
(echo ROM_Name	CRC	Size	Project64_id	RiceVideo_id	Version	Media	Region	Internal_Title) >spreadsheet.txt

dir /b /a:-d "%_folder%*.zip" "%_folder%*.z64" "%_folder%*.bin" >_temp\index.1

REM ****** line counter ************
for /f "delims=" %%g in (_temp\index.1) do set /a "_total_lines+=1"

if %_total_lines%==0 (
	title ERROR
	echo THIS FOLDER IS EMPTY
	pause & exit
)

for /f "delims=" %%g in (_temp\index.1) do (
	call :ext_zipinfo "%%g"
	
)
move /y output.txt "%_path%"
move /y spreadsheet.txt "%_path%"
del _temp\temp.1 _temp\index.1 & rd _temp

title FINISHED
pause & exit


:ext_zipinfo

REM ****** line counter ************	
set /a "_count_lines+=1"
set /a "_percent=(%_count_lines%*100)/%_total_lines%
title N64 info: %_count_lines% / %_total_lines% ^( %_percent% %% ^)


set _zip=1
if not "%~x1"==".zip" (
	set "_rom_path=%_folder%%~1"
	set "_rom=%~1"
	(echo.) >_temp\temp.1
	set _zip=0
	set "_crc=NO_INFO"
	set "_size=NO_INFO"
	goto skip_zip
)

"%_7zip%" e -y "%_folder%%~1" -o_temp >nul
"%_7zip%" l -slt "%_folder%%~1" >_temp\temp.1

REM //There are 2 resluts, will save the 2nd with a leading space 
for /f "tokens=2 delims==" %%h in ('findstr /b /c:"Path = " _temp\temp.1') do set "_rom_path=%%h"
set "_rom=%_rom_path:~1%"
set "_rom_path=_temp\%_rom_path:~1%"



REM //test for n64 extension?

for /f "tokens=2 delims==" %%h in ('findstr /b /c:"CRC = " _temp\temp.1') do set "_crc=%%h"
set "_crc=%_crc:~1%"

for /f "tokens=2 delims==" %%h in ('findstr /b /c:"Size = " _temp\temp.1') do set "_size=%%h"
set "_size=%_size:~1%"


:skip_zip
"%_path%\_bin\xxd" -u -s 0x30 -l 16 "%_rom_path%" >>_temp\temp.1
"%_path%\_bin\xxd" -u -g 4 -s 0x10 -l 16 "%_rom_path%" >>_temp\temp.1
"%_path%\_bin\xxd" -u -s 0x20 -l 16 "%_rom_path%" >>_temp\temp.1


if %_zip%==1 del "%_rom_path%"


REM //only need the 2 first characters
for /f "tokens=9 delims= " %%h in ('findstr /b /c:"00000030: " _temp\temp.1') do set "_code=%%h"
set "_version=%_code:~2,2%"
set "_code=%_code:~0,2%"



for /f "tokens=2,3 delims= " %%h in ('findstr /b /c:"00000010: " _temp\temp.1') do (
	set "_crc1=%%h"
	set "_crc2=%%i"
)

REM //2 parts to make the complete header title
for /f "delims=" %%h in ('findstr /b /c:"00000020: " _temp\temp.1') do set "_title=%%h"
for /f "delims=" %%h in ('findstr /b /c:"00000030: " _temp\temp.1') do set "_title2=%%h"

set _media=%_title2:~-5,1%


set "_surreal=%_crc1%-%_crc2%-C:%_code%"
set "_rice=%_crc1:~6,1%%_crc1:~7,1%%_crc1:~4,1%%_crc1:~5,1%%_crc1:~2,1%%_crc1:~3,1%%_crc1:~0,1%%_crc1:~1,1%%_crc2:~6,1%%_crc2:~7,1%%_crc2:~4,1%%_crc2:~5,1%%_crc2:~2,1%%_crc2:~3,1%%_crc2:~0,1%%_crc2:~1,1%-%_code%"

REM //convert to lower case
set "_rice=%_rice:A=a%"
set "_rice=%_rice:B=b%"
set "_rice=%_rice:C=c%"
set "_rice=%_rice:D=d%"
set "_rice=%_rice:E=e%"
set "_rice=%_rice:F=f%"

set "_version0=Unknown"
if "%_version%"=="00" set "_version0=1.0" & goto skip_version
if "%_version%"=="01" set "_version0=1.1 ^(Rev 1^)" & goto skip_version
if "%_version%"=="02" set "_version0=1.2 ^(Rev 2^)" & goto skip_version
if "%_version%"=="03" set "_version0=1.3 ^(Rev 3^)"
:skip_version

set "_media0=Unknown"
if "%_media%"=="N" set "_media0=Cart" & goto skip_media
if "%_media%"=="D" set "_media0=64DD disk" & goto skip_media
if "%_media%"=="C" set "_media0=Cartridge part of expandable game" & goto skip_media
if "%_media%"=="E" set "_media0=64DD expansion for cart" & goto skip_media
if "%_media%"=="Z" set "_media0=Aleck64 cart"
:skip_media

set "_region=Unknown"
if "%_code%"=="45" set "_region=North America" & goto skip_region
if "%_code%"=="4A" set "_region=Japanese" & goto skip_region
if "%_code%"=="50" set "_region=European ^(basic spec.^)" & goto skip_region
if "%_code%"=="58" set "_region=European" & goto skip_region
if "%_code%"=="59" set "_region=European" & goto skip_region
if "%_code%"=="00" set "_region=Unknown" & goto skip_region
if "%_code%"=="41" set "_region=Asian ^(NTSC^)" & goto skip_region
if "%_code%"=="42" set "_region=Brazilian" & goto skip_region
if "%_code%"=="44" set "_region=German" & goto skip_region
if "%_code%"=="53" set "_region=Spanish" & goto skip_region
if "%_code%"=="46" set "_region=French" & goto skip_region
if "%_code%"=="49" set "_region=Italian" & goto skip_region
if "%_code%"=="48" set "_region=Dutch" & goto skip_region
if "%_code%"=="4B" set "_region=Korean" & goto skip_region
if "%_code%"=="4E" set "_region=Canadian" & goto skip_region
if "%_code%"=="55" set "_region=Australian" & goto skip_region
if "%_code%"=="57" set "_region=Scandinavian" & goto skip_region
if "%_code%"=="37" set "_region=Beta" & goto skip_region
if "%_code%"=="43" set "_region=Chinese" & goto skip_region
if "%_code%"=="47" set "_region=Gateway 64 ^(NTSC^)" & goto skip_region
if "%_code%"=="4C" set "_region=Gateway 64 ^(PAL^)"
:skip_region


echo ----------------------------------------------------
echo File Name      : "%_rom%"
echo ROM Tilte      : "%_title:~-16,16%%_title2:~-16,4%"
echo Region         : %_region%
echo Media          : %_media0%
echo Version        : %_version0% 
echo CRC            : %_crc%
echo Size           : %_Size%
echo Project64 id   : %_surreal%
echo RiceVideo id   : %_rice%
echo.


if not "%_folder%"=="" (
	(echo "%_rom%"	%_crc%	%_size%	%_surreal%	%_rice%	%_version0%	%_media0%	%_region%	"%_title:~-16,16%%_title2:~-16,4%") >>spreadsheet.txt
)


(echo ----------------------------------------------------
echo File Name      : "%_rom%"
echo ROM Tilte      : "%_title:~-16,16%%_title2:~-16,4%"
echo Region         : %_region%
echo Media          : %_media0%
echo Version        : %_version0%
echo CRC            : %_crc%
echo Size           : %_Size%
echo Project64 id   : %_surreal%
echo RiceVideo id   : %_rice%
echo.) >output.txt



if not exist "%_path%\surreal64" exit /b

REM \\********** surreal64ce *********************

findstr /b /i /c:"[%_surreal%]" "%_path%\surreal64\surreal.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in Surreal.ini
	
	(echo.
	echo [%_surreal%]) >>"%_path%\surreal64\surreal.ini"
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Game Name=%%h) >>"%_path%\surreal64\surreal.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo Alternate Title=%%~nh) >>"%_path%\surreal64\surreal.ini"
	(echo Comments=) >>"%_path%\surreal64\surreal.ini"
	
)

findstr /b /i /c:"[%_surreal%]" "%_path%\surreal64\1964_11.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in 1964_11.ini
	
	(echo.
	echo [%_surreal%]) >>"%_path%\surreal64\1964_11.ini"
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Game Name=%%h) >>"%_path%\surreal64\1964_11.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo Alternate Title=%%~nh) >>"%_path%\surreal64\1964_11.ini"
	(echo RDRAM Size=1
	echo Save Type=5
	echo EEPROM Size=2
	echo Emulator=1
	echo Check Self-modifying Code=8
	echo TLB=1
	echo Use Register Caching=1
	echo Counter Factor=2
	echo FPU Hack=1
	echo DMA=2
	echo Link 4KB Blocks=1
	echo Advanced Block Analysis=1
	echo Assume 32bit=2) >>"%_path%\surreal64\1964_11.ini"
	
)

findstr /b /i /c:"[%_surreal%]" "%_path%\surreal64\1964.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in 1964.ini
	
	(echo.
	echo [%_surreal%]) >>"%_path%\surreal64\1964.ini"
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Game Name=%%h) >>"%_path%\surreal64\1964.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo Alternate Title=%%~nh) >>"%_path%\surreal64\1964.ini"
	(echo RDRAM Size=1
	echo Save Type=5
	echo EEPROM Size=2
	echo Emulator=1
	echo Check Self-modifying Code=8
	echo TLB=1
	echo Use Register Caching=1
	echo Counter Factor=2
	echo FPU Hack=1
	echo DMA=2
	echo Link 4KB Blocks=1
	echo Advanced Block Analysis=1
	echo Assume 32bit=2) >>"%_path%\surreal64\1964.ini"
	
)

findstr /b /i /c:"[%_surreal%]" "%_path%\surreal64\Project64.rdb" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in Project64.rdb
	
	(echo.
	echo [%_surreal%]) >>"%_path%\surreal64\Project64.rdb"
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Internal Name=%%h) >>"%_path%\surreal64\Project64.rdb"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo Good Name=%%~nh) >>"%_path%\surreal64\Project64.rdb"
	
	(echo RDRAM Size=4
	echo Counter Factor=2
	echo Save Type=First Save Type
	echo CPU Type=Recompiler
	echo Self-modifying code Method=Default
	echo Use TLB=Yes
	echo Linking=On
	echo Reg Cache=Yes
	echo Delay SI=No
	echo SP Hack=No) >>"%_path%\surreal64\Project64.rdb"
	
)

findstr /b /i /c:"{%_rice%}" "%_path%\surreal64\RiceVideo6.1.2.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in RiceVideo6.1.2.ini
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo.&echo //%%~nh&echo {%_rice%}) >>"%_path%\surreal64\RiceVideo6.1.2.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Name=%%h) >>"%_path%\surreal64\RiceVideo6.1.2.ini"
	
)


findstr /b /i /c:"{%_rice%}" "%_path%\surreal64\RiceVideo5.6.0.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in RiceVideo5.6.0.ini
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo.&echo //%%~nh&echo {%_rice%}) >>"%_path%\surreal64\RiceVideo5.6.0.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Name=%%h) >>"%_path%\surreal64\RiceVideo5.6.0.ini"
	
)

findstr /b /i /c:"{%_rice%}" "%_path%\surreal64\RiceDaedalus5.3.1.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in RiceDaedalus5.3.1.ini
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo.&echo //%%~nh&echo {%_rice%}) >>"%_path%\surreal64\RiceDaedalus5.3.1.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Name=%%h) >>"%_path%\surreal64\RiceDaedalus5.3.1.ini"
	
)

findstr /b /i /c:"{%_rice%}" "%_path%\surreal64\RiceDaedalus5.1.0.ini" >nul 2>&1
if %errorlevel%==1 (
	echo NOT found in RiceDaedalus5.1.0.ini
	
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"File Name      : " output.txt') do (echo.&echo //%%~nh&echo {%_rice%}) >>"%_path%\surreal64\RiceDaedalus5.1.0.ini"
	for /f tokens^=2^ delims^=^" %%h in ('findstr /b /c:"ROM Tilte      : " output.txt') do (echo Name=%%h) >>"%_path%\surreal64\RiceDaedalus5.1.0.ini"
	
)


exit /b

