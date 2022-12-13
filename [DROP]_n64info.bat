@echo off
rem //option for alt titles in configuration files
rem //0=use z64 rom name,1=use datafile title,2=use zip file name
set /a _option=0

set "_home=%~dp0"
set /a _opt_surreal=0
if exist "%_home%surreal64\" set /a _opt_surreal=1

if "%~1"=="" (
	if exist "patch_ocarina" goto patch_zelda
	if exist "patch_mask" goto patch_zelda
)

if /i not "%~nx1"=="surreal.ini" goto skip_menu
	set "_surreal_ini=%~1"
	
	echo.             Surreal.ini Options
	echo. ----------------------------------------------------
	echo.
	echo. 1. Rename all *.png images to surreal.ini CRC1
	echo. 2. Add Configuration to surreal.ini from "Saves" folder
	echo. 3. Create "Saves" folder from surreal.ini ^(only 6.0b EWJ format^)
	echo. 4. Rename all ROMs using surreal.ini
	echo. 5. Make synopsis files
	echo.
	choice /c:12345 /n /m "Enter Option Number: "
	if %errorlevel% equ 1 goto rename_img
	if %errorlevel% equ 2 goto add_saves
	if %errorlevel% equ 3 goto make_saves
	if %errorlevel% equ 4 goto rename_zip
	if %errorlevel% equ 5 goto make_synop
	
:skip_menu

if exist "%temp%\temp.txt" del "%temp%\temp.txt"
if exist "%_home%output.txt" del "%_home%output.txt"

rem // not needed, since not using saves folder for new games
rem //look for defaults in surreal.ini
REM if %_opt_surreal% equ 1 (
	REM set "_emu=0"
	REM set "_video=2"
	REM set "_audio=3"
	REM set "_vmem=5"
	REM set "_rsp=2"
	REM set "_1964mem=8"
	REM set "_1964pg=4"
	REM set "_pj64mem=16"
	REM set "_pj64pg=4"
	REM >nul 2>&1 findstr /lb "[Settings]" "%_home%surreal64\surreal.ini"&&(
		REM for /f "tokens=1,2 delims==" %%g in ('findstr /lb "Default" "%_home%surreal64\surreal.ini"') do (
			REM if "%%g"=="Default Emulator" set "_emu=%%h"
			REM if "%%g"=="Default Video Plugin" set "_video=%%h"
			REM if "%%g"=="Default Audio Plugin" set "_audio=%%h"
			REM if "%%g"=="Default Rsp Plugin" set "_rsp=%%h"
			REM if "%%g"=="Default Max Video Mem" set "_vmem=%%h"
			REM if "%%g"=="Default 1964 Dyna Mem" set "_1964mem=%%h"
			REM if "%%g"=="Default 1964 Paging Mem" set "_1964pg=%%h"
			REM if "%%g"=="Default PJ64 Dyna Mem" set "_pj64mem=%%h"
			REM if "%%g"=="Default PJ64 Paging Mem" set "_pj64pg=%%h"
		REM )
	REM )
REM )

rem //check if its a folder
if "%~a1"=="d----------" cd /d "%~1"&goto skip_addmore

:add_more
if not "%~1"=="" (
	for %%g in ("%~1") do (echo %%~nxg)>>"%temp%\temp.txt"
	shift&goto add_more
)

:skip_addmore
call :error_check
call :check_files

rem //look for a datafile, includes full path
setlocal enabledelayedexpansion
set /a _index=0
for %%g in ("%_home%*.dat") do (
	set "_dat[!_index!]=%%~ng"
	set /a _index+=1
)

REM for /l %%g in (0,1,%_index%) do (
	REM set _datrom="%%_datrom[%%g]%%",!_datrom!
	REM set _dat="^!_dat[%%g]^!",!_dat!
REM )


setlocal disabledelayedexpansion


if not exist "%_home%output.csv" (echo "Zip name","ROM name","Header tilte","Region","Media","Version","CRC","Size","Duplicate_CRC1","Project64_id","Daedalus_id","%_dat[0]%")>"%_home%output.csv"

for /f "usebackq delims=" %%g in ("%temp%\temp.txt") do (
	call :get_n64 "%%g" "%%~xg"
)

del "%temp%\temp.txt"
title FINISHED&pause&exit
rem // ----------------------------- end of script -------------------------------------------

:get_n64

if not "%~2"==".zip" goto skip_zip

rem //need the name of the compressed file
for /f "tokens=1,* skip=1 delims== " %%g in ('^(%_7zip% l -slt -spd -- "%~1"^)^|findstr /lb /c:"Path =" /c:"Size =" /c:"CRC ="') do (
	if "%%g"=="Path" set "_rom=%%h"
	if "%%g"=="Size" set "_size=%%h"
	if "%%g"=="CRC" set "_crc=%%h"
)
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

if "%_title%"=="" set _title=NO_TITLE

rem //delete extracted 7zip file
if "%~2"==".zip" del "%_rom%"

set "_media=%_title2:~-5,1%"
set "_title=%_title%%_title2:~0,-12%"
rem //remove doble quotes form title becuse n64dd roms will crash script
set "_title=%_title:"='%"
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
set "_datrom[0]="
if not "%_dat[0]%"=="" (
	for /f tokens^=2^ delims^=^" %%g in ('findstr /il /c:"crc=\"%_crc%\"" "%_home%%_dat[0]%.dat"') do set "_datrom[0]=%%g"
)

set "_datrom[1]="
if not "%_dat[1]%"=="" (
	for /f tokens^=2^ delims^=^" %%g in ('findstr /il /c:"crc=\"%_crc%\"" "%_home%%_dat[1]%.dat"') do set "_datrom[1]=%%g"
)



echo ----------------------------------------------------
if defined _dat[0] echo. Datafile       : "%_datrom[0]%"
if defined _dat[1] echo. Datafile 2     : "%_datrom[1]%"
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
if defined _dat[0] echo Datafile       : "%_datrom[0]%"
if defined _dat[1] echo Datafile 2     : "%_datrom[1]%"
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
rem //look for dup crc1
set "_dup1="
>nul findstr /l /c:"%_crc1%" "%_home%output.csv"&&set _dup1=TRUE
>nul findstr /l /c:"%_crc%" "%_home%output.csv"||(echo "%_file%","%_rom%","%_title%","%_region%","%_media%","%_version%","%_crc%","%_size%","%_dup1%","%_surreal%","%_rice%","%_datrom[0]%")>>"%_home%output.csv"

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
	if not "%_datrom[0]%"=="" set "_rom=%_datrom[0]%"
)
if %_option% equ 2 (
	if not "%_file%"=="" set "_rom=%_file%"
)

rem //pre-configuration for ocarina & mask hacks
REM if "%_file%"=="" (set "_comp=%_rom%")else (set "_comp=%_file%")

REM set _rdram=1&set _rdram2=4
REM set _save=5&set _eeprom=2&set "_save2=First Save Type"
REM set _cf=2

REM if /i not "%_comp%"=="%_comp:LoZ OoT=%" (
	REM set _rdram=2&set _rdram2=8
	REM set _save=3&set _eeprom=1&set _save2=Sram
	
REM )
REM if /i not "%_comp%"=="%_comp:LoZ MM=%" (
	REM set _rdram=2&set _rdram2=8
	REM set _save=4&set _eeprom=1&set _save2=FlashRam
	REM set _cf=3
REM )


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


rem //******* add header if surreal.ini dosenot already exsits
rem //add entry to surreal.ini if game was not found
>nul 2>&1 findstr /bli /c:"[%_surreal%]" "%_home%surreal64\surreal.ini"||(
	echo New game added to Surreal.ini!!&echo.
	(echo New game added to Surreal.ini!!&echo.)>>"%_home%output.txt"
	
	(echo.&echo [%_surreal%]
	for %%g in ("%_title%") do echo Game Name=%%~g
	for %%g in ("%_rom%") do echo Alternate Title=%%~ng
	echo Comments=)>>"%_home%surreal64\surreal.ini"
	
	rem //remove, this not really useful, since there will be no save files for new added games
	REM if %_opt_saves% equ 1 (
		REM if /i exist "%_home%saves\%_crc1%\%_crc1%.ini" (
			REM for /f "tokens=1,2 delims==" %%h in ('findstr /lb "preferedemu videoplugin iAudioPlugin iRspPlugin dwMaxVideoMem dw1964DynaMem dw1964PagingMem dwPJ64DynaMem dwPJ64PagingMem" "%_home%saves\%_crc1%\%_crc1%.ini"') do (
				REM if "%%h"=="preferedemu" if not "%_emu%"=="%%i"  echo Emulator=%%i
				REM if "%%h"=="videoplugin" if not "%_video%"=="%%i" echo Video Plugin=%%i
				REM if "%%h"=="iAudioPlugin" if not "%_audio%"=="%%i" echo Audio Plugin=%%i
				REM if "%%h"=="iRspPlugin" if not "%_rsp%"=="%%i" echo Rsp Plugin=%%i
				REM if "%%h"=="dwMaxVideoMem" if not "%_vmem%"=="%%i" echo Max Video Mem=%%i
				REM if "%%h"=="dw1964DynaMem" if not "%_1964mem%"=="%%i" echo 1964 Dyna Mem=%%i
				REM if "%%h"=="dw1964PagingMem" if not "%_1964pg%"=="%%i" echo 1964 Paging Mem=%%i
				REM if "%%h"=="dwPJ64DynaMem" if not "%_pj64mem%"=="%%i" echo PJ64 Dyna Mem=%%i
				REM if "%%h"=="dwPJ64PagingMem" if not "%_pj64pg%"=="%%i" echo PJ64 Paging Mem=%%i
			REM )>>"%_home%surreal64\surreal.ini"
		REM )
	REM )
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

exit /b


:check_files
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

rem // ------------------------------- add config script --------------------------------------------------

:add_saves

cls
if not exist "%_home%saves\" title ERROR&echo SAVES FOLDER WAS NOT FOUND&pause&exit

rem //emulator defaults
set "_emu=0"
set "_video=2"
set "_audio=3"
set "_vmem=5"
set "_rsp=2"
set "_1964mem=8"
set "_1964pg=4"
set "_pj64mem=16"
set "_pj64pg=4"

if exist "notfound.log" del notfound.log
if exist "surreal.ini.new" del surreal.ini.new

rem //look for defaults
>nul 2>&1 findstr /lb "[Settings]" "%_surreal_ini%"&&(
	(echo [Settings]
	findstr /lb "Rom Media Skin Save Screenshot Default" "%_surreal_ini%")>>surreal.ini.new
	
	for /f "tokens=1,2 delims==" %%g in ('findstr /lb "Default" "%_surreal_ini%"') do (
		if "%%g"=="Default Emulator" set "_emu=%%h"
		if "%%g"=="Default Video Plugin" set "_video=%%h"
		if "%%g"=="Default Audio Plugin" set "_audio=%%h"
		if "%%g"=="Default Rsp Plugin" set "_rsp=%%h"
		if "%%g"=="Default Max Video Mem" set "_vmem=%%h"
		if "%%g"=="Default 1964 Dyna Mem" set "_1964mem=%%h"
		if "%%g"=="Default 1964 Paging Mem" set "_1964pg=%%h"
		if "%%g"=="Default PJ64 Dyna Mem" set "_pj64mem=%%h"
		if "%%g"=="Default PJ64 Paging Mem" set "_pj64pg=%%h"
	)
)
rem //can read surreal.ini line by line ***
rem //get line number, and full surreal id from surreal.ini
for /f "tokens=1-3 delims=[:]" %%g in ('findstr /nir /c:"\[[A-F0-9][A-F0-9:-]*\]" "%_surreal_ini%"') do (
	call :search_crc1 "%%g" "%%h:%%i"
)

title FINISHED
pause&exit

:search_crc1

set "_line=%~1"
set "_crc1=%~2"
set "_crc1=%_crc1:~0,8%"

(echo.&echo [%~2])>>surreal.ini.new

rem //finds the game in surreal.ini extracts lines then exit
for /f "usebackq skip=%_line% tokens=1,2 delims==" %%g in ("%_surreal_ini%") do (
	(if /i "%%g"=="Game Name" echo %%g=%%h
	if /i "%%g"=="Alternate Title" echo %%g=%%h
	if /i "%%g"=="Comments" echo %%g=%%h)>>surreal.ini.new
	
	(echo "%%g"|findstr /ir /c:"\[[A-F0-9][A-F0-9:-]*\]")&&goto exit_surreal_file
)
:exit_surreal_file

rem //if theres no config file, log and exit loop
if /i not exist "%_home%saves\%_crc1%\%_crc1%.ini" (
	echo %_crc1% Not FOUND
	(echo %_crc1%)>>notfound.log
	exit /b
)

rem //reads saves .ini file
for /f "tokens=1,2 delims==" %%h in ('findstr /lb "preferedemu videoplugin iAudioPlugin iRspPlugin dwMaxVideoMem dw1964DynaMem dw1964PagingMem dwPJ64DynaMem dwPJ64PagingMem" "%_home%saves\%_crc1%\%_crc1%.ini"') do (
	(if "%%h"=="preferedemu" if not "%_emu%"=="%%i"  echo Emulator=%%i
	if "%%h"=="videoplugin" if not "%_video%"=="%%i" echo Video Plugin=%%i
	if "%%h"=="iAudioPlugin" if not "%_audio%"=="%%i" echo Audio Plugin=%%i
	if "%%h"=="iRspPlugin" if not "%_rsp%"=="%%i" echo Rsp Plugin=%%i
	if "%%h"=="dwMaxVideoMem" if not "%_vmem%"=="%%i" echo Max Video Mem=%%i
	if "%%h"=="dw1964DynaMem" if not "%_1964mem%"=="%%i" echo 1964 Dyna Mem=%%i
	if "%%h"=="dw1964PagingMem" if not "%_1964pg%"=="%%i" echo 1964 Paging Mem=%%i
	if "%%h"=="dwPJ64DynaMem" if not "%_pj64mem%"=="%%i" echo PJ64 Dyna Mem=%%i
	if "%%h"=="dwPJ64PagingMem" if not "%_pj64pg%"=="%%i" echo PJ64 Paging Mem=%%i)>>surreal.ini.new
)


exit /b

rem // ------------------------- rename images script ---------------------------------

:rename_img
cd /d "%_home%"
REM if not exist "*.png" title ERROR&echo NO PNG IMAGES FOUND&pause&exit

cls
echo. Rename png images Options
echo ------------------------------
echo.
echo. 1. CRC1 --------^> Alt. Tilte
echo. 2. Alt. Title --^> CRC1
echo. 3. CRC1 --------^> Game Name
echo. 4. Game Name ---^> CRC1
echo.
choice /n /c:1234 /m "Enter Option: "
if %errorlevel% equ 1 set _opt=1&set "_alt=Alternate Title"
if %errorlevel% equ 2 set _opt=2&set "_alt=Alternate Title"
if %errorlevel% equ 3 set _opt=1&set "_alt=Game Name"
if %errorlevel% equ 4 set _opt=2&set "_alt=Game Name"

REM md _REN_img
rem //can be changed to "Game Name"
for /f "tokens=1,2 delims==" %%g in ('findstr /bri /c:"%_alt%=" /c:"\[[A-F0-9][:A-F0-9-]*\]" "%_surreal_ini%"') do (
	call :rename_img2 "%%g" "%%h"

)
title FINISHED
pause&exit

:rename_img2

if /i "%~1"=="%_alt%" (
	set "_title=%~2"

)else (
	for /f "delims=[-" %%g in ("%~1") do set "_crc1=%%g"
	exit /b
)

if %_opt% equ 1 (
	echo "%_crc1% --------> %_title%"
	REM copy /y "%_crc1%.png" "_REN_img\%_title%.png" >nul 2>&1
	REM copy /y "%_crc1%.txt" "_REN_img\%_title%.txt" >nul 2>&1
	REM copy /y "%_crc1%.jpg" "_REN_img\%_title%.jpg" >nul 2>&1
	
	ren "%_crc1%.png" "%_title%.png" >nul 2>&1
	ren "%_crc1%.txt" "%_title%.txt" >nul 2>&1
	ren "%_crc1%.jpg" "%_title%.jpg" >nul 2>&1
)else (
	echo "%_title% -------> %_crc1%"
	REM copy /y "%_title%.png" "_REN_img\%_crc1%.png" >nul 2>&1
	REM copy /y "%_title%.txt" "_REN_img\%_crc1%.txt" >nul 2>&1
	REM copy /y "%_title%.jpg" "_REN_img\%_crc1%.jpg" >nul 2>&1
	
	ren "%_title%.png" "%_crc1%.png" >nul 2>&1
	ren "%_title%.txt" "%_crc1%.txt" >nul 2>&1
	ren "%_title%.jpg" "%_crc1%.jpg" >nul 2>&1
)
exit /b

rem // ---------------------------------- rename zip script ---------------------------------------------- 
:rename_zip

cd /d "%_home%"

cls
call :error_check

if not exist "*.zip" echo NO ROMS FOUND&pause&exit

echo. Renaming options
echo.--------------------------
echo.
echo. 1. Game Name ^(surreal.ini^)
echo. 2. Alt. Game Name ^(surreal.ini^)
echo. 3. Header CRC1
echo. 4. ROMs CRC
echo. 5. Zipped ROM z64
echo.
choice /n /c:12345 /m "Enter Option Number: "
if %errorlevel% equ 1 set "_alt=Game Name"
if %errorlevel% equ 2 set "_alt=Alternate Title"
if %errorlevel% equ 3 set "_alt=header"
if %errorlevel% equ 4 set "_alt=crc"
if %errorlevel% equ 5 set "_alt=rom"

for %%g in (*.zip) do (
	call :rename_games "%%g"
)
pause&exit

:rename_games

rem //need the name of the compressed file
for /f "tokens=1,* skip=1 delims== " %%g in ('^(%_7zip% l -slt -spd -- "%~1"^)^|findstr /lb /c:"Path =" /c:"CRC ="') do (
	if "%%g"=="Path" set "_rom=%%h"
	if "%%g"=="CRC" set "_crc=%%h"
)

if "%_alt%"=="crc" (
	ren "%~1" "%_crc%.zip"
	exit /b
)

if "%_alt%"=="rom" (
	ren "%~1" "%_rom:~0,-4%.zip"
	exit /b
)

rem //extract rom to use with xxd
%_7zip% e -y -spd -- "%~1" >nul

for /f "tokens=2,3" %%g in ('^(%_xxd% -u -g 4 -s 0x10 -l 16 "%_rom%"^)') do (
	set "_crc1=%%g"
	set "_crc2=%%h"
)

rem //delete extracted 7zip file
del "%_rom%"

if "%_alt%"=="header" (
	ren "%~1" "%_crc1%.zip"
	exit /b
)

set "_line="
for /f "delims=:" %%g in ('findstr /linb /c:"[%_crc1%-%_crc2%" "%_surreal_ini%"') do set /a _line=%%g
if "%_line%"=="" (
	echo %_crc1% "%_rom%" NOT FOUND&exit /b
)

for /f "usebackq skip=%_line% tokens=1,2 delims==" %%g in ("%_surreal_ini%") do (
	if /i "%%g"=="%_alt%" (
		set "_game=%%h"
		goto exit_loop2
	)	
)
:exit_loop2

ren "%~1" "%_game%.zip"

exit /b


rem // --------------------------------- patch ocarina of time and majoras mask -----------------------------

:patch_zelda

call :error_check

rem //needs xxd, 7zip
if exist "patch_ocarina" (
	echo.&echo THE LEGEND OF ZELDA
	set _patch[1]="0000020: 544845204C4547454E44204F46205A45"
	set _patch[2]="0000030: 4C444120"
	cd patch_ocarina&(2>nul md patched)
	call :patch_zelda2
)
if exist "patch_mask" (
	echo.&echo ZELDA MAJORA'S MASK
	set _patch[1]="0000020: 5A454C4441204D414A4F52412753204D"
	set _patch[2]="0000030: 41534B20"
	cd patch_mask&(2>nul md patched)
	call :patch_zelda2
)
title FISNISHED&pause&exit

:patch_zelda2
for %%g in (*.z64 *.zip) do (
	if "%%~xg"==".zip" (
		for /f "tokens=1,* skip=1 delims== " %%h in ('^(%_7zip% l -slt -spd -- "%%g"^)^|findstr /lb /c:"Path ="') do (
			if "%%~xi"==".z64" (
				1>nul %_7zip% e -y -spd -opatched -- "%%g"
				echo %_patch[1]%|xxd -r - ".\patched\%%i"
				echo %_patch[2]%|xxd -r - ".\patched\%%i"
				echo. "%%g\%%i" ...............PATCHED!!
				1>nul %_7zip% a -sdel -spd -- ".\patched\%%g" ".\patched\%%i"	
			)
		)
	)else (
		1>nul copy /y "%%g" patched
		echo %_patch[1]%|xxd -r - ".\patched\%%g"
		echo %_patch[2]%|xxd -r - ".\patched\%%g"
		echo. "%%g" ...............PATCHED!!
		1>nul %_7zip% a -sdel -spd -- ".\patched\%%~ng.zip" ".\patched\%%g"
	)
)

cd ..
exit /b

rem // ----------------------------------------- make synopsis script ------------------------------------------------------
:make_synop

md synopsis
for /f "tokens=1,2 delims==" %%g in ('findstr /bir /c:"\[[A-F0-9][A-F0-9:-]*\]" /c:"Game Name=" /c:"Alternate Title=" "%_surreal_ini%"') do (
	call :get_lines "%%g" "%%h"
)

pause&exit

:get_lines
rem //will catch no info after equal sign, however, game name and alt title will always have info
if "%~2"=="" set "_crc1=%~1"&exit /b
if /i "%~1"=="Game Name" set "_game=%~2"&exit /b
if /i "%~1"=="Alternate Title" set "_alt=%~2"
set "_crc1=%_crc1:~1,8%"

(for %%g in ("%_game%") do echo Filename: %%~g.zip
for %%g in ("%_alt%") do echo Name: %%~g
echo Rating: None
echo Release Year: 
echo Developer: Indie
echo Publisher: Hack
echo Genre: 
echo Players: 1
echo _________________________)>"synopsis\%_crc1%.txt"

set "_crc1="&set "_game="&set "_alt="
exit /b


rem // -------------------------------------------------- make saves script -----------------------------------------------
:make_saves
rem //only for surreal64 6.0b with EWJ configuration in game names

cls
1>nul 2>&1 findstr /li /c:"(1964-" /c:"(1964x11-" /c:"(PJ64x16-" /c:"(PJ64x14-" "%_surreal_ini%"||(title ERROR&echo SURREAL.INI IS NOT IN EWJ FORMAT&pause&exit)

md Saves_new
set _found=0
set "_comt="
set "_game="
set "_crc1="
for /f "tokens=1,2 delims==" %%g in ('findstr /bri /c:"\[[A-F0-9][A-F0-9:-]*\]" /c:"Game Name=" /c:"Comments=" "%_surreal_ini%"') do (
	call :make_save2 "%%g" "%%h"
)

pause&exit

:make_save2

set "_str=%~1"
if "%_str:~0,1%"=="[" (
	set "_crc1=%_str:~1,8%"
	set _found=1
	exit /b
)

if %_found% equ 0 exit /b

if /i "%~1"=="Game Name" (
	set "_game=%~2"
	exit /b
)

if /i "%~1"=="Comments" set "_comt=%~2"
set _found=0

rem //6.0b will read pj64x16=1, and pj64x14=3
rem //6.1b will read pj64x16=3, and pj64x14=1
set _emu=0
set _vid=2
set _vmem=4
set _audio=3
set _pj64mem=16
set _pj64pg=4
set _1964mem=10
set _1964pg=4
set _rsp=2

set _skip=false
set _core=1964

for /f "tokens=2 delims=)(" %%g in ("%_game%") do (
	for /f "tokens=1,2 delims=-" %%h in ("%%g") do (
		if "%%h"=="1964" set _emu=0
		if /i "%%h"=="1964x11" set _emu=4
		if /i "%%h"=="PJ64x14" set _emu=3&set _core=pj64
		if /i "%%h"=="PJ64x16" set _emu=1&set _core=pj64
		if /i "%%h"=="UltraHLE" set _emu=2
		if "%%i"=="5.10" set _vid=0
		if "%%i"=="5.31" set _vid=1
		if "%%i"=="5.60" set _vid=2
		if "%%i"=="6.11" set _vid=3
		if "%%i"=="6.12" set _vid=4
	)	
)

if "%_comt%"=="" goto skip_comt
if not "%_comt%"=="%_comt:Basic=%" set _audio=2
if not "%_comt%"=="%_comt:auto=%" set _vmem=0
if not "%_comt%"=="%_comt:DM:8=%" set _1964mem=8
if not "%_comt%"=="%_comt:DM:14=%" set _pj64mem=14
if not "%_comt%"=="%_comt:pg:6=%" set _1964pg=6&set _pj64pg=6
if not "%_comt%"=="%_comt:skipframes=%" set _skip=true
:skip_comt

md "Saves_new\%_crc1%" 2>nul

(echo [Settings])>"%_folder%")>"Saves_new\%_crc1%\%_crc1%.ini"

(echo preferedemu=%_emu%
echo videoplugin=%_vid%
echo iAudioPlugin=%_audio%
echo iRspPlugin=%_rsp%
echo dw1964DynaMem=%_1964mem%
echo dw1964PagingMem=%_1964pg%
echo dwPJ64DynaMem=%_pj64mem%
echo dwPJ64PagingMem=%_pj64pg%
echo dwMaxVideoMem=%_vmem%
echo bUseRspAudio=false
echo dwUltraCodeMem=5
echo dwUltraGroupMem=10
echo bUseLLERSP=false
echo iPagingMethod=0
echo Sensitivity=10
echo DefaultPak=3
echo FlickerFilter=1
echo TextureMode=3
echo VertexMode=2
echo VSync=0
echo AntiAliasMode=0
echo SoftDisplayFilter=false
echo FrameSkip=%_skip%
echo LinearFog=false
echo EnableController1=true
echo EnableController2=true
echo EnableController3=true
echo EnableController4=true
echo ShowDebug=0
echo XBOX_CONTROLLER_DEAD_ZONE=8600.000000
echo Deadzone=26.000000
echo ControllerConfig[0]=0
echo ControllerConfig[1]=1
echo ControllerConfig[2]=2
echo ControllerConfig[3]=3
echo ControllerConfig[4]=8
echo ControllerConfig[5]=9
echo ControllerConfig[6]=10
echo ControllerConfig[7]=11
echo ControllerConfig[8]=4
echo ControllerConfig[9]=5
echo ControllerConfig[10]=6
echo ControllerConfig[11]=7
echo ControllerConfig[12]=12
echo ControllerConfig[13]=16
echo ControllerConfig[14]=18
echo ControllerConfig[15]=22
echo ControllerConfig[16]=13
echo ControllerConfig[17]=23
echo ControllerConfig[18]=15
echo ControllerConfig[19]=0
echo ControllerConfig[20]=1
echo ControllerConfig[21]=2
echo ControllerConfig[22]=3
echo ControllerConfig[23]=8
echo ControllerConfig[24]=9
echo ControllerConfig[25]=10
echo ControllerConfig[26]=11
echo ControllerConfig[27]=4
echo ControllerConfig[28]=5
echo ControllerConfig[29]=6
echo ControllerConfig[30]=7
echo ControllerConfig[31]=12
echo ControllerConfig[32]=16
echo ControllerConfig[33]=18
echo ControllerConfig[34]=22
echo ControllerConfig[35]=13
echo ControllerConfig[36]=23
echo ControllerConfig[37]=15
echo ControllerConfig[38]=0
echo ControllerConfig[39]=1
echo ControllerConfig[40]=2
echo ControllerConfig[41]=3
echo ControllerConfig[42]=8
echo ControllerConfig[43]=9
echo ControllerConfig[44]=10
echo ControllerConfig[45]=11
echo ControllerConfig[46]=4
echo ControllerConfig[47]=5
echo ControllerConfig[48]=6
echo ControllerConfig[49]=7
echo ControllerConfig[50]=12
echo ControllerConfig[51]=16
echo ControllerConfig[52]=18
echo ControllerConfig[53]=22
echo ControllerConfig[54]=13
echo ControllerConfig[55]=23
echo ControllerConfig[56]=15
echo ControllerConfig[57]=0
echo ControllerConfig[58]=1
echo ControllerConfig[59]=2
echo ControllerConfig[60]=3
echo ControllerConfig[61]=8
echo ControllerConfig[62]=9
echo ControllerConfig[63]=10
echo ControllerConfig[64]=11
echo ControllerConfig[65]=4
echo ControllerConfig[66]=5
echo ControllerConfig[67]=6
echo ControllerConfig[68]=7
echo ControllerConfig[69]=12
echo ControllerConfig[70]=16
echo ControllerConfig[71]=18
echo ControllerConfig[72]=22
echo ControllerConfig[73]=13
echo ControllerConfig[74]=23
echo ControllerConfig[75]=15
echo EnableHDTV=false
echo FullScreen=false)>>"Saves_new\%_crc1%\%_crc1%.ini"


set "_comt="
set "_game="
set "_crc1="

exit /b