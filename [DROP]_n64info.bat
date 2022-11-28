@echo off
rem //option for alt titles in configuration files
rem //0=use rom name,1=use datafile title,2=use zip file name
set /a _option=2

set "_home=%~dp0"
rem //if saves folder its found
set /a _opt_saves=0
if exist "%_home%saves" set /a _opt_saves=1
rem //if surreal64 folder its found
set /a _opt_surreal=0
if exist "%_home%surreal64" set /a _opt_surreal=1

if exist "%temp%\temp.txt" del "%temp%\temp.txt"
if exist "%_home%output.txt" del "%_home%output.txt"

rem //check if its a folder
if "%~a1"=="d----------" cd /d "%~1"&goto skip_addmore

:add_more
if not "%~1"=="" (
	for %%g in ("%~1") do (echo %%~nxg)>>"%temp%\temp.txt"
	shift&goto add_more
)

:skip_addmore
call :error_check

rem //look for a datafile, includes full path
set "_dat="
for %%g in ("%_home%*.dat") do (
	set "_dat=%%~ng"
)

if not exist "%_home%output.csv" (echo "Zip name","ROM name","Header tilte","Region","Media","Version",CRC,Size,Project64_id,Daedalus_id,"%_dat%")>"%_home%output.csv"

for /f "usebackq delims=" %%g in ("%temp%\temp.txt") do (
	call :get_n64 "%%g" "%%~xg"
)

del "%temp%\temp.txt"
title FINISHED&pause&exit
rem // ----------------------------- end of script -------------------------------------------

:get_n64

if not "%~2"==".zip" goto skip_zip

rem //need the name of the compressed file
for /f "tokens=1,2 skip=1 delims==" %%g in ('^(%_7zip% l -slt -spd -- "%~1"^)^|findstr /lb /c:"Path =" /c:"Size =" /c:"CRC ="') do (
	if "%%g"=="Path " set "_rom=%%h"
	if "%%g"=="Size " set "_size=%%h"
	if "%%g"=="CRC " set "_crc=%%h"
)
set "_crc=%_crc:~1%"
set "_size=%_size:~1%"
set "_rom=%_rom:~1%"
set "_file=%~1"

rem //extract rom to use with xxd
%_7zip% e -y -spd -- "%~1" >nul

:skip_zip

rem //non-zip files
if not "%~2"==".zip" (
	for /f "tokens=4" %%g in ('^(%_7zip% h -spd -- "%~1"^)^|findstr /bl /c:"CRC32  for data:"') do set "_crc=%%g"
	set "_size=%~z1"
	
	set "_rom=%~1"
	set "_file="
)

for /f "tokens=9,*" %%g in ('^(%_xxd% -u -s 0x20 -l 16 "%_rom%"^)') do set "_title=%%h"
for /f "tokens=9,*" %%g in ('^(%_xxd% -u -s 0x30 -l 16 "%_rom%"^)') do (
	set "_code=%%g"
	set "_title2=%%h"
)
for /f "tokens=2,3" %%g in ('^(%_xxd% -u -g 4 -s 0x10 -l 16 "%_rom%"^)') do (
	set "_crc1=%%g"
	set "_crc2=%%h"
)


rem //delete extracted 7zip file
if "%~2"==".zip" del "%_rom%"

set "_media=%_title2:~-5,1%"
set "_title=%_title%%_title2:~0,-12%"
set "_version=%_code:~2,2%"
set "_code=%_code:~0,2%"

rem //remove trailing spaces from title
:remove_space
if "%_title:~-1,1%"==" " (
	set "_title=%_title:~0,-1%"
	goto :remove_space
)

set "_surreal=%_crc1%-%_crc2%-C:%_code%"
set "_rice=%_crc1:~6,1%%_crc1:~7,1%%_crc1:~4,1%%_crc1:~5,1%%_crc1:~2,1%%_crc1:~3,1%%_crc1:~0,1%%_crc1:~1,1%%_crc2:~6,1%%_crc2:~7,1%%_crc2:~4,1%%_crc2:~5,1%%_crc2:~2,1%%_crc2:~3,1%%_crc2:~0,1%%_crc2:~1,1%-%_code%"

REM //convert to lower case
set "_rice=%_rice:A=a%"
set "_rice=%_rice:B=b%"
set "_rice=%_rice:C=c%"
set "_rice=%_rice:D=d%"
set "_rice=%_rice:E=e%"
set "_rice=%_rice:F=f%"

if "%_version%"=="00" set "_version=1.0"&goto skip_version
if "%_version%"=="01" set "_version=1.1 (Rev 1)"&goto skip_version
if "%_version%"=="02" set "_version=1.2 (Rev 2)"&goto skip_version
if "%_version%"=="03" set "_version=1.3 (Rev 3)"&goto skip_version
set "_version=Unknown"
:skip_version
if "%_media%"=="N" set "_media=Cart"&goto skip_media
if "%_media%"=="D" set "_media=64DD disk"&goto skip_media
if "%_media%"=="C" set "_media=Cartridge part of expandable game"&goto skip_media
if "%_media%"=="E" set "_media=64DD expansion for cart"&goto skip_media
if "%_media%"=="Z" set "_media=Aleck64 cart"&goto skip_media
set "_media=Unknown"
:skip_media
if "%_code%"=="45" set "_region=North America"&goto skip_region
if "%_code%"=="4A" set "_region=Japanese"&goto skip_region
if "%_code%"=="50" set "_region=European (basic spec.)"&goto skip_region
if "%_code%"=="58" set "_region=European"&goto skip_region
if "%_code%"=="59" set "_region=European"&goto skip_region
if "%_code%"=="00" set "_region=Unknown"&goto skip_region
if "%_code%"=="41" set "_region=Asian (NTSC)"&goto skip_region
if "%_code%"=="42" set "_region=Brazilian"&goto skip_region
if "%_code%"=="44" set "_region=German"&goto skip_region
if "%_code%"=="53" set "_region=Spanish"&goto skip_region
if "%_code%"=="46" set "_region=French"&goto skip_region
if "%_code%"=="49" set "_region=Italian"&goto skip_region
if "%_code%"=="48" set "_region=Dutch"&goto skip_region
if "%_code%"=="4B" set "_region=Korean"&goto skip_region
if "%_code%"=="4E" set "_region=Canadian"&goto skip_region
if "%_code%"=="55" set "_region=Australian"&goto skip_region
if "%_code%"=="57" set "_region=Scandinavian"&goto skip_region
if "%_code%"=="37" set "_region=Beta"&goto skip_region
if "%_code%"=="43" set "_region=Chinese"&goto skip_region
if "%_code%"=="47" set "_region=Gateway 64 (NTSC)"&goto skip_region
if "%_code%"=="4C" set "_region=Gateway 64 (PAL)"&goto skip_region
set "_region=Unknown"
:skip_region

rem //get title from datafile
set "_datrom="
if not "%_dat%"=="" (
	for /f tokens^=2^ delims^=^" %%g in ('findstr /il /c:"crc=\"%_crc%\"" "%_home%%_dat%.dat"') do set "_datrom=%%g"
)

echo ----------------------------------------------------
echo. Datafile       : "%_datrom%"
echo. Zip File       : "%_file%"
echo. File Name      : "%_rom%"
echo. ROM Tilte      : "%_title%"
echo. Region         : "%_region%"
echo. Media          : "%_media%"
echo. Version        : "%_version%"
echo. CRC            : %_crc%
echo. Size           : %_Size%
echo. Project64 id   : %_surreal%
echo. RiceVideo id   : %_rice%
echo.

(echo ----------------------------------------------------
echo Datafile       : "%_datrom%"
echo Zip File       : "%_file%"
echo File Name      : "%_rom%"
echo ROM Tilte      : "%_title%"
echo Region         : "%_region%"
echo Media          : "%_media%"
echo Version        : "%_version%"
echo CRC            : %_crc%
echo Size           : %_Size%
echo Project64 id   : %_surreal%
echo RiceVideo id   : %_rice%
echo.) >>"%_home%output.txt"

rem // only add entry if crc dosent exist
>nul findstr /l /c:"%_crc%" "%_home%output.csv"||(echo "%_file%","%_rom%","%_title%","%_region%","%_media%","%_version%",%_crc%,%_size%,%_surreal%,%_rice%,"%_datrom%")>>"%_home%output.csv"

set /a "_count_lines+=1"
set /a "_percent=(%_count_lines%*100)/%_total_lines%
title N64 info: %_count_lines% / %_total_lines% ^( %_percent% %% ^)

rem //clear variables?
if %_opt_surreal% equ 0 (
	set "_crc="
	set "_crc1="
	set "_crc2="
	set "_code="
	exit /b
)

rem // -----------------------------  update surreal64 configuration files ----------------------------------------
rem // if file dosent exist will make a new one, if surreal64 folder exist

if %_option% equ 1 (
	if not "%_datrom%"=="" set "_rom=%_datrom%"
)
if %_option% equ 2 (
	if not "%_file%"=="" set "_rom=%_file%"
)

>nul 2>&1 findstr /bli /c:"[%_surreal%]" "%_home%surreal64\Project64.rdb"||(
echo.&echo [%_surreal%]
for %%g in ("%_title%") do echo Internal Name=%%~g
for %%g in ("%_rom%") do echo Good Name=%%~ng
echo RDRAM Size=4
echo Counter Factor=2
echo Save Type=First Save Type
echo CPU Type=Recompiler
echo Self-modifying code Method=Default
echo Use TLB=Yes
echo Linking=On
echo Reg Cache=Yes
echo Delay SI=No
echo SP Hack=No)>>"%_home%surreal64\Project64.rdb"

for %%g in (1964_11.ini 1964.ini) do (
	>nul 2>&1 findstr /bli /c:"[%_surreal%]" "%_home%surreal64\%%g"||(
	echo.&echo [%_surreal%]
	for %%h in ("%_title%") do echo Game Name=%%~h
	for %%h in ("%_rom%") do echo Alternate Title=%%~nh
	echo RDRAM Size=1
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
	echo Assume 32bit=2)>>"%_home%surreal64\%%g"
)

for %%g in (RiceVideo6.1.2.ini RiceVideo6.1.0.ini RiceVideo5.6.0.ini RiceDaedalus5.3.1.ini RiceDaedalus5.1.0.ini) do (
	>nul 2>&1 findstr /bli /c:"{%_rice%}" "%_home%surreal64\%%g"||(
		for %%h in ("%_rom%") do echo.&echo //%%~nh&echo {%_rice%}
		for %%h in ("%_title%") do echo Name=%%~h
	)>>"%_home%surreal64\%%g"
)

rem //search for configuration ini in save folder
set /a _config=0
if %_opt_saves% equ 0 goto skip_saves
if /i exist "%_home%saves\%_crc1%\%_crc1%.ini" (
	set /a _config=1
	for /f "tokens=1,2 delims==" %%h in ('findstr /lb "preferedemu videoplugin iAudioPlugin iRspPlugin dwMaxVideoMem dw1964DynaMem dw1964PagingMem dwPJ64DynaMem dwPJ64PagingMem" "%_home%saves\%_crc1%\%_crc1%.ini"') do (
		if "%%h"=="preferedemu" set "_emu=%%i"
		if "%%h"=="videoplugin" set "_video=%%i"
		if "%%h"=="iAudioPlugin" set "_audio=%%i"
		if "%%h"=="iRspPlugin" set "_rsp=%%i"
		if "%%h"=="dwMaxVideoMem" set "_vmem=%%i"
		if "%%h"=="dw1964DynaMem" set "_1964mem=%%i"
		if "%%h"=="dw1964PagingMem" set "_1964pg=%%i"
		if "%%h"=="dwPJ64DynaMem" set "_pj64mem=%%i"
		if "%%h"=="dwPJ64PagingMem" set "_pj64pg=%%i"
	)	
)

:skip_saves

>nul 2>&1 findstr /bli /c:"[%_surreal%]" "%_home%surreal64\surreal.ini"||(
	echo New game added to Surreal.ini!!&echo.
	(echo New game added to Surreal.ini!!&echo.)>>"%_home%output.txt"
	
	(echo.&echo [%_surreal%]
	for %%g in ("%_title%") do echo Game Name=%%~g
	for %%g in ("%_rom%") do echo Alternate Title=%%~ng
	echo Comments=)>>"%_home%surreal64\surreal.ini"
	
	if %_config% equ 1 (
		(echo Emulator=%_emu%
		echo Video Plugin=%_video%
		echo Audio Plugin=%_audio%
		echo Rsp Plugin=%_rsp%
		echo Max Video Mem=%_vmem%
		echo 1964 Dyna Mem=%_1964mem%
		echo 1964 Paging Mem=%_1964pg%
		echo PJ64 Dyna Mem=%_pj64mem%
		echo PJ64 Paging Mem=%_pj64pg%)>>"%_home%surreal64\surreal.ini"
	)
)

rem //clear variables
set "_crc="
set "_crc1="
set "_crc2="
set "_code="
exit /b

rem // ---------------------------- check for errors before staring script --------------------------
:error_check
if exist "%_home%7z.exe" set _7zip="%_home%7z.exe"&goto error_check_1
if exist "%_home%_bin\7z.exe" set _7zip="%_home%_bin\7z.exe"&goto error_check_1
if exist "c:\windows\system32\7z.exe" set "_7zip=7z.exe"&goto error_check_1
if exist "%programfiles%\7-Zip\7z.exe" set _7zip="%programfiles%\7-Zip\7z.exe"&goto error_check_1
if exist "%programfiles(x86)%\7-Zip\7z.exe" set _7zip="%programfiles(x86)%\7-Zip\7z.exe"&goto error_check_1
title ERROR&echo THIS SCRIPT NEEDS 7zip&pause&exit
:error_check_1

if exist "%_home%xxd.exe" set _xxd="%_home%xxd.exe"&goto error_check_2
if exist "%_home%_bin\xxd.exe" set _xxd="%_home%_bin\xxd.exe"&goto error_check_2
if exist "c:\windows\system32\xxd.exe" set "_xxd=xxd.exe"&goto error_check_2
title ERROR&echo THIS SCRIPT NEEDS xxd.exe&pause&exit
:error_check_2

if not exist "%temp%\temp.txt" (
	(dir /b *.z64 *.n64 *.v64 *.bin *.ndd *.zip)>"%temp%\temp.txt"
)

rem //test, and count files
if exist "%_home%error.log" del "%_home%error.log"
set /a "_total_lines=0"
set /a "_count_lines=0"
for /f "usebackq delims=" %%g in ("%temp%\temp.txt") do (
	if exist "%%g" ( 
		set /a _total_lines+=1
	)else (
		(echo "%%g")>>"%_home%error.log"
	)
)

if exist "%_home%error.log" (
	title ERROR&echo RENAME THIS FILES:
	type "%_home%error.log"
	pause&exit
)

if %_total_lines% equ 0 (
	title ERROR
	echo THERE ARE NO FILES&pause&exit
)	

exit /b