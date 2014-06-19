@echo off
setlocal
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Script Initialization
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

set usbpath=%~dp0%

:checkDumpIt
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Checking DumpIt Integrity
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
fciv %usbpath%DumpIt.exe -sha1 > checksums.txt

for /f "tokens=1 skip=3 delims= " %%a in (checksums.txt) do (
   find "%%a" <"originalSigs.txt" || >>result2.txt echo %%a
    if exist result2.txt ( goto end ) else ( goto CheckOs)
   
)

:CheckOS
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Checking Operating System
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (set rawcopy=%usbpath%RawCopy_v1.0.0.7\RawCopy.exe) else (set rawcopy=%usbpath%RawCopy_v1.0.0.7\RawCopy64.exe)


:CheckifXP
systeminfo > systeminfo.log
findstr /i xp systeminfo.log >nul
IF %ERRORLEVEL% == 0 SET XP=1
findstr /i vista systeminfo.log >nul
IF %ERRORLEVEL% == 0 SET XP=0
findstr /i windows.7 systeminfo.log >nul
IF %ERRORLEVEL% == 0 SET XP=0
findstr /i windows.8 systeminfo.log >nul
IF %ERRORLEVEL% == 0 SET XP=0

md %~dp0%Output



:checkrawcopy
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Checking Rawcopy Integrity
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

fciv %rawcopy% -sha1 >> checksums.txt



for /f "tokens=1 skip=3 delims= " %%a in (checksums.txt) do (
   find "%%a" <"test.txt" || >>result1.txt echo %%a
    if exist result1.txt ( goto end ) else ( goto RegistryAcquisition)
   
)


 
:RegistryAcquisition
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Registry Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

mkdir "%~dp0%"\Output\RegistryFiles
set REG_OUTPUT="%~dp0%"\Output\RegistryFiles
set OLDDIR=%cd%
pushd %systemroot%\system32\config\

for /f "delims=" %%f in ('dir /a:d /b') do (
	mkdir %REG_OUTPUT%\%%f
	for /f "delims=" %%A in ('dir /b /a:-d /s %cd%\%%f') do (
		%rawcopy% "%%A" %REG_OUTPUT%\%%f\
	)
)
for /f "delims=" %%f in ('dir /a:-d /b') do (
	%OLDDIR%\RawCopy_v1.0.0.7\RawCopy64.exe "%cd%\%%f" %REG_OUTPUT%
)

popd


:MFTAcquisition
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			MFT Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
%rawcopy% C:0 "%~dp0%"\Output


ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			NTuser Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
md %usbpath%Output\Users
ECHO Getting Users
if %XP% == 0 (for /f %%f in ('dir C:\Users\* /b') do md %usbpath%Output\Users\%%~nf

		for /f %%f in ('dir C:\Users\* /b') do %rawcopy% C:\Users\%%~nf\NTUSER.dat %usbpath%Output\Users\%%~nf
) ELSE ( for /f %%f in ('dir C:\"Documents and settings"\* /b') do md %usbpath%Output\Users\%%~nf
		for /f %%f in ('dir C:\"Documents and settings"\* /b') do %rawcopy% C:\"Documents and settings"\%%~nf\NTUSER.DAT %usbpath%Output\Users\%%~nf
)

:MemoryAcquisition
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Memory Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
dumpit.exe

echo %usbpath%

ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			Storing Output Checksums
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
fciv.exe -r %usbpath% -sha1 > OutputChecksums.txt

:end
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO 			End of Script
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
endlocal