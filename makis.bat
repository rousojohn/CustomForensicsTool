@echo off
setlocal
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Script Initialization
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

set usbpath=%~dp0%
set OUT_DIR=%usbpath%Output
set HTML_DIR=%OUT_DIR%\html
set REG_OUTPUT=%OUT_DIR%\RegistryFiles
set USERS_DIR=%OUT_DIR%\Users
set INDEX_HTML_FILE=filename.html
set SCRIPT_LOG_FILE=scriptLogFile.txt

md %OUT_DIR%
md %HTML_DIR%



call:OpenIndexHtmlFile %INDEX_HTML_FILE%

:timeLineFile
echo.
echo ***************************************************************************
echo ***************************************************************************
echo 			Generating Filesystem timeline
echo ***************************************************************************
echo ***************************************************************************
echo.

rem fls.exe -i raw -f ntfs -z CST6CDT -r -p -m c: \\.\c: > tmp.txt
now.exe [Completed timeline bodyfile generation.] >> %SCRIPT_LOG_FILE%

call:MakeIndexEntry %INDEX_HTML_FILE% "timelineBodyFile.html" "Timeline File Log"

call:OpenHtmlFile "timelineBodyFile"
type tmp.txt >> %HTML_DIR%\timelineBodyFile.html
call:CloseHtmlFile "timelineBodyFile"
del tmp.txt



:checkWinPrefetchView
echo.
echo ***************************************************************************
echo ***************************************************************************
echo Checking WinPrefetchView Tool
echo ***************************************************************************
echo ***************************************************************************
echo.
fciv %usbpath%winprefetchview.exe -sha1 > checksums.txt

for /f "tokens=1 skip=3 delims= " %%a in (checksums.txt) do (
   find "%%a" <"test.txt" || >>result2.txt echo %%a
    if exist result2.txt ( goto end ) else ( goto getPrefetch)
)

:getPrefetch
winprefetchview.exe /shtml %HTML_DIR%\winpf_view.html /sort "~Modified Time"
now.exe [Completed WinPrefetchView on the Prefetch directory.] > %SCRIPT_LOG_FILE%

call:MakeIndexEntry %INDEX_HTML_FILE% "winpf_view.html" "Windows Prefeched Files"




:checkDumpIt
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Checking DumpIt Integrity
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
fciv %usbpath%DumpIt.exe -sha1 > checksums.txt

for /f "tokens=1 skip=3 delims= " %%a in (checksums.txt) do (
   find "%%a" <"test.txt" || >>result2.txt echo %%a
    if exist result2.txt ( goto end ) else ( goto CheckOs)
   
)

:CheckOS
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Checking Operating System
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


call:MakeIndexEntry %INDEX_HTML_FILE% "systeminfo.html" "System Information Log"

call:OpenHtmlFile "systeminfo"
type systeminfo.log >> %HTML_DIR%\systeminfo.html
call:CloseHtmlFile "systeminfo"






:checkrawcopy
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Checking Rawcopy Integrity
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
ECHO Registry Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
now.exe [Copying the registry files for offline analysis] >> %SCRIPT_LOG_FILE%
mkdir %REG_OUTPUT%

set OLDDIR=%cd%
pushd %systemroot%\system32\config\

for /f "delims=" %%f in ('dir /a:d /b') do (
	mkdir %REG_OUTPUT%\%%f
	for /f "delims=" %%A in ('dir /b /a:-d /s %cd%\%%f') do (
		%rawcopy% "%%A" %REG_OUTPUT%\%%f\ >> %OLDDIR%\tmp.txt
	)
)
for /f "delims=" %%f in ('dir /a:-d /b') do (
	%rawcopy% "%cd%\%%f" %REG_OUTPUT% >> %OLDDIR%\tmp.txt
)


popd

call:MakeIndexEntry %INDEX_HTML_FILE% "registry.html" "Registry Files Log"

call:OpenHtmlFile "registry"
type %OLDDIR%\tmp.txt >> %HTML_DIR%\registry.html
call:CloseHtmlFile "registry"
del %OLDDIR%\tmp.txt


:MFTAcquisition
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO MFT Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.
now.exe [Copying the MFT for offline analysis] >> %SCRIPT_LOG_FILE%
%rawcopy% C:0 %OUT_DIR% >>tmp.txt

call:MakeIndexEntry %INDEX_HTML_FILE% "mft.html" "Master File Table Log"
call:OpenHtmlFile "mft"
type tmp.txt >> %HTML_DIR%\mft.html
call:CloseHtmlFile "mft"
del tmp.txt



ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO NTuser Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

md %USERS_DIR% 
ECHO Getting Users

dir %USERS_DIR% /b >> tmp.txt
if %XP% == 0 (for /f %%f in ('dir C:\Users\* /b') do md %USERS_DIR%\%%~nf 

for /f %%f in ('dir C:\Users\* /b') do %rawcopy% C:\Users\%%~nf\NTUSER.dat %USERS_DIR%\%%~nf >> tmp.txt  
) ELSE ( for /f %%f in ('dir C:\"Documents and settings"\* /b') do md %USERS_DIR%\%%~nf
for /f %%f in ('dir C:\"Documents and settings"\* /b') do %rawcopy% C:\"Documents and settings"\%%~nf\NTUSER.DAT %USERS_DIR%\%%~nf >> tmp.txt
)

call:MakeIndexEntry %INDEX_HTML_FILE% "users.html" "Existing Users Log"

call:OpenHtmlFile "users"
type tmp.txt >> %HTML_DIR%\users.html
call:CloseHtmlFile "users"
del tmp.txt


:ComputerState
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Gather Information about the state of the computer
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

ECHO  Running PSInfo.exe on %COMPUTERNAME%.
now.exe [Running PSInfo.exe -d -s on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
psinfo -d -s /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "psinfo"
type tmp.txt >> %HTML_DIR%\psinfo.html
call:CloseHtmlFile "psinfo"
call:MakeIndexEntry %INDEX_HTML_FILE% "psinfo.html" "PSInfo Log"


ECHO  Running pendmoves on %COMPUTERNAME%.
now.exe [Running pendmoves on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
pendmoves /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "pendmoves"
type tmp.txt >> %HTML_DIR%\pendmoves.html
call:CloseHtmlFile "pendmoves"
call:MakeIndexEntry %INDEX_HTML_FILE% "pendmoves.html" "Pendmoves Log"

ECHO  Running net use on %COMPUTERNAME%.
now.exe [Running net use on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
net use 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "net_use"
type tmp.txt >> %HTML_DIR%\net_use.html
call:CloseHtmlFile "net_use"
call:MakeIndexEntry %INDEX_HTML_FILE% "net_use.html" "Net Use Log"

ECHO  Running net view on %COMPUTERNAME%.
now.exe [Running net view on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
net view %COMPUTERNAME% 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "net_view"
type tmp.txt >> %HTML_DIR%\net_view.html
call:CloseHtmlFile "net_view"
call:MakeIndexEntry %INDEX_HTML_FILE% "net_view.html" "Net View Log"


ECHO  Running net share on %COMPUTERNAME%.
now.exe [Running net share on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
net share 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "net_share"
type tmp.txt >> %HTML_DIR%\net_share.html
call:CloseHtmlFile "net_share"
call:MakeIndexEntry %INDEX_HTML_FILE% "net_share.html" "Net Share Log"

ECHO  Running net session on %COMPUTERNAME%.
now.exe [Running net session on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
net session 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "net_session"
type tmp.txt >> %HTML_DIR%\net_session.html
call:CloseHtmlFile "net_session"
call:MakeIndexEntry %INDEX_HTML_FILE% "net_session.html" "Net Session Log"

ECHO  Running net file on %COMPUTERNAME%.
now.exe [Running net file on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
net file 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "net_file"
type tmp.txt >> %HTML_DIR%\net_file.html
call:CloseHtmlFile "net_file"
call:MakeIndexEntry %INDEX_HTML_FILE% "net_file.html" "Net File Log"


ECHO  Running tasklist on %COMPUTERNAME%.
now.exe [Running tasklist /svc /fo csv on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
tasklist /svc /fo csv 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "tasklist"
type tmp.txt >> %HTML_DIR%\tasklist.html
call:CloseHtmlFile "tasklist"
call:MakeIndexEntry %INDEX_HTML_FILE% "tasklist.html" "Tasklist Log"

ECHO  Running driverquery /v on %COMPUTERNAME%.
now.exe [Running driverquery on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
driverquery /fo csv /si 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "driverquery"
type tmp.txt >> %HTML_DIR%\driverquery.html
call:CloseHtmlFile "driverquery"
call:MakeIndexEntry %INDEX_HTML_FILE% "driverquery.html" "Driverquery Log"

ECHO  Running sc.exe /query on %COMPUTERNAME%.
now.exe [Running sc.exe /query on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
sc.exe query 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "sc"
type tmp.txt >> %HTML_DIR%\sc.html
call:CloseHtmlFile "sc"
call:MakeIndexEntry %INDEX_HTML_FILE% "sc.html" "Sc Log"

ECHO  Running schtasks.exe on %COMPUTERNAME%.
now.exe [Running schtasks.exe on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
schtasks.exe /query /v /fo list 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "schtasks"
type tmp.txt >> %HTML_DIR%\schtasks.html
call:CloseHtmlFile "schtasks"
call:MakeIndexEntry %INDEX_HTML_FILE% "schtasks.html" "Schtasks Log"

ECHO  Running at.exe on %COMPUTERNAME%.
now.exe [Running at.exe on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
at.exe 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "at"
type tmp.txt >> %HTML_DIR%\at.html
call:CloseHtmlFile "at"
call:MakeIndexEntry %INDEX_HTML_FILE% "at.html" "At Log"

ECHO  Running set on %COMPUTERNAME%.
now.exe [Running set on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
set 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "set"
type tmp.txt >> %HTML_DIR%\set.html
call:CloseHtmlFile "set"
call:MakeIndexEntry %INDEX_HTML_FILE% "set.html" "Set Log"

ECHO  Running ftype on %COMPUTERNAME%.
now.exe [Running ftype on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
ftype 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "ftype"
type tmp.txt >> %HTML_DIR%\ftype.html
call:CloseHtmlFile "ftype"
call:MakeIndexEntry %INDEX_HTML_FILE% "ftype.html" "Ftype Log"

ECHO  Running openfiles /query /v against %COMPUTERNAME%.
now.exe [Running openfiles /query on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
openfiles /query /fo csv 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "openfiles"
type tmp.txt >> %HTML_DIR%\openfiles.html
call:CloseHtmlFile "openfiles"
call:MakeIndexEntry %INDEX_HTML_FILE% "openfiles.html" "Openfiles Log"

ECHO  Running assoc on %COMPUTERNAME%.
now.exe [Running assoc on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
assoc 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "assoc"
type tmp.txt >> %HTML_DIR%\assoc.html
call:CloseHtmlFile "assoc"
call:MakeIndexEntry %INDEX_HTML_FILE% "assoc.html" "Assoc Log"


ECHO  Running PSList.exe on %COMPUTERNAME%.
now.exe [Running PSList.exe -t on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
PSList.exe -t /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

now.exe [Running PSList.exe -mx on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
PSList.exe -mx /AcceptEula 2>> %SCRIPT_LOG_FILE% >> tmp.txt

call:OpenHtmlFile "PSList"
type tmp.txt >> %HTML_DIR%\PSList.html
call:CloseHtmlFile "PSList"
call:MakeIndexEntry %INDEX_HTML_FILE% "pslist.html" "PSList Log"

ECHO  Running listdlls.exe on %COMPUTERNAME%.
now.exe [Running listdlls.exe on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
listdlls.exe /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "listdlls"
type tmp.txt >> %HTML_DIR%\listdlls.html
call:CloseHtmlFile "listdlls"
call:MakeIndexEntry %INDEX_HTML_FILE% "listdlls.html" "Listdlls Log"

ECHO  Running handle.exe on %COMPUTERNAME%.
now.exe [Running handle.exe -au on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
handle.exe -au /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "handle"
type tmp.txt >> %HTML_DIR%\handle.html
call:CloseHtmlFile "handle"
call:MakeIndexEntry %INDEX_HTML_FILE% "handle.html" "Handle Log"

ECHO  Running PSservice.exe on %COMPUTERNAME%.
now.exe [Running PSservice.exe on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
PSservice.exe /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "PSservice"
type tmp.txt >> %HTML_DIR%\PSservice.html
call:CloseHtmlFile "PSservice"
call:MakeIndexEntry %INDEX_HTML_FILE% "PSservice.html" "PSservice Log"

ECHO  Running PSFile.exe on %COMPUTERNAME%.
now.exe [Running PSFile.exe on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
PSFile.exe /AcceptEula 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "PSFile"
type tmp.txt >> %HTML_DIR%\PSFile.html
call:CloseHtmlFile "PSFile"
call:MakeIndexEntry %INDEX_HTML_FILE% "PSFile.html" "PSFile Log"


ECHO  Running showacls on %COMPUTERNAME%.
now.exe [Running showacls on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
showacls 2>> %SCRIPT_LOG_FILE% > tmp.txt

call:OpenHtmlFile "showacls"
type tmp.txt >> %HTML_DIR%\showacls.html
call:CloseHtmlFile "showacls"
call:MakeIndexEntry %INDEX_HTML_FILE% "showacls.html" "Showacls Log"

:BrowserInfo
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Various Browser Information
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

set BROWSER_OUT_DIR=%OUT_DIR%\BrowsersInfo
set IE=%BROWSER_OUT_DIR%\IE
set FF=%BROWSER_OUT_DIR%\FF
set CHROME=%BROWSER_OUT_DIR%\FF
md %BROWSER_OUT_DIR%
md %IE%
md %FF%
md %CHROME%

now.exe [Now gathering information from various browsers] >> %SCRIPT_LOG_FILE%

:I_E
ECHO  Running iehv on %COMPUTERNAME%.
now.exe [Running iehv on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%

if %XP% == 0 (
  for /F %%i in ('dir /b c:\Users') do iehv.exe /stab "%IE%\iehv_%%i.csv" -user "%%i" 2>> %SCRIPT_LOG_FILE%
) else (
  for /F %%i in ('dir /b "c:\Documents and Settings"') do iehv.exe /stab "%IE%\iehv_%%i.csv" -user "%%i" 2>> %SCRIPT_LOG_FILE%
)

echo. > tmp.txt
for /F %%i in ('dir /b /a:-d /s "%IE%"') do (
  echo "%%i" >> tmp.txt
  type "%%i" >> tmp.txt
  echo. >> tmp.txt
)

call:OpenHtmlFile "iehv"
type tmp.txt >> %HTML_DIR%\iehv.html
call:CloseHtmlFile "iehv"
call:MakeIndexEntry %INDEX_HTML_FILE% "iehv.html" "Internet Explorer History Log"


:F_F
ECHO    Check Firefox installation
now.exe [Check Firefox installation.] >> %SCRIPT_LOG_FILE%
IF NOT EXIST "%PROGRAMFILES%\Mozilla Firefox" GOTO SKIPFF

now.exe [Searching for Firefox profiles and running MozillaHistoryView on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
ECHO    Now searching for Firefox profiles and running MozillaHistoryView.
ECHO. 
ECHO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ECHO  This may generate some "The system cannot find the 
ECHO  path specified" error messages if a user doesn't  
ECHO  have a Firefox profile.                          
ECHO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ECHO.

if %XP%==0 (
  for /F %%u in ('dir /b c:\Users') do for /F %%p in ('dir /b c:\Users\%%u\AppData\Roaming\Mozilla\Firefox\Profiles\') do @MozillaHistoryView.exe /sverhtml  "%FF%\ffhv_%%u_%%p.csv" -file "c:\Users\%%u\AppData\Roaming\Mozilla\Firefox\Profiles\%%p\places.sqlite" 2>> %SCRIPT_LOG_FILE%  
) else (
  for /F %%u in ('dir /b "c:\Documents and Settings"') do for /F %%p in ('dir /b "c:\Documents and Settings\%%u\Application Data\Mozilla\Firefox\Profiles\"') do @MozillaHistoryView.exe /sverhtml  "%FF%\ffhv_%%u_%%p.csv" -file "c:\Documents and Settings\%%u\Application Data\Mozilla\Firefox\Profiles\%%p\places.sqlite" 2>> %SCRIPT_LOG_FILE%  
)

echo. > tmp.txt
for /F %%i in ('dir /b /a:-d /s "%FF%"') do (
  echo "%%i" >> tmp.txt
  type "%%i" >> tmp.txt
  echo. >> tmp.txt
)

call:OpenHtmlFile "MozillaHistoryView"
type tmp.txt >> %HTML_DIR%\MozillaHistoryView.html
call:CloseHtmlFile "MozillaHistoryView"
call:MakeIndexEntry %INDEX_HTML_FILE% "MozillaHistoryView.html" "Mozilla Firefox History Log"

:SKIPFF
ECHO    Firefox doesn't seem to be installed.  MozillaHistoryView skipped.
now.exe [Firefox doesn't seem to be installed - MozillaHistoryView skipped.] >> %SCRIPT_LOG_FILE%

:G_CHROME
ECHO  Running Google ChromeCacheView.
now.exe [Running Google ChromeCacheView.] >> %SCRIPT_LOG_FILE%

if %XP%==0 (
  for /F %%i in ('dir /b c:\Users') do @chromecacheview.exe /sverhtml "%CHROME%\chromecacheview_%%i.csv" -folder "c:\Users\%%i\AppData\Local\Google\Chrome\User Data\Default\Cache" 2>> %SCRIPT_LOG_FILE%  
) else (
  for /F %%i in ('dir /b "c:\Documents and Settings"') do @chromecacheview.exe /sverhtml "%CHROME%\chromecacheview_%%i.csv" -folder "c:\Documents and Settings\%%i\Application Data\Local Settings\Google\Chrome\User Data\Default\Cache" 2>> %SCRIPT_LOG_FILE%  
)

echo. > tmp.txt
for /F %%i in ('dir /b /a:-d /s "%CHROME%"') do (
  echo "%%i" >> tmp.txt
  type "%%i" >> tmp.txt
  echo. >> tmp.txt
)

call:OpenHtmlFile "chromecacheview"
type tmp.txt >> %HTML_DIR%\chromecacheview.html
call:CloseHtmlFile "chromecacheview"
call:MakeIndexEntry %INDEX_HTML_FILE% "chromecacheview.html" "Google Chrome History Log"


:MemoryAcquisition
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Memory Acquisition
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

now.exe [Running dumpit.exe on %COMPUTERNAME%.] >> %SCRIPT_LOG_FILE%
dumpit.exe 2> tmp.txt

call:MakeIndexEntry %INDEX_HTML_FILE% "memory.html" "Memory Log"

call:OpenHtmlFile "memory"
type tmp.txt >> %HTML_DIR%\memory.html
call:CloseHtmlFile "memory"
del tmp.txt

move %COMPUTERNAME%*.raw %OUT_DIR%



echo %usbpath%

ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO Storing Output Checksums
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

now.exe [Calculate Checksums of Gathered Information] >> %SCRIPT_LOG_FILE%
fciv.exe -r %usbpath% -sha1 > OutputChecksums.txt

call:MakeIndexEntry %INDEX_HTML_FILE% "checksums.html" "Checksums"

call:OpenHtmlFile "checksums"
type OutputChecksums.txt >> %HTML_DIR%\checksums.html
call:CloseHtmlFile "checksums"


:end
ECHO.
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO End of Script
ECHO ***************************************************************************
ECHO ***************************************************************************
ECHO.

call:MakeIndexEntry %INDEX_HTML_FILE% "logs.html" "Logs"

call:OpenHtmlFile "logs"
type %SCRIPT_LOG_FILE% >> %HTML_DIR%\logs.html
call:CloseHtmlFile "logs"
call:CloseIndexHtmlFile  %INDEX_HTML_FILE%

rem ============================================================================
rem
rem
REM 			CLEAN UP AREA --> delete all temp files produced by the script
rem
rem ============================================================================

del tmp.txt
del %SCRIPT_LOG_FILE%
del systeminfo.log

set usbpath=
set OUT_DIR=
set HTML_DIR=
set REG_OUTPUT=
set USERS_DIR=
set INDEX_HTML_FILE=
set SCRIPT_LOG_FILE=
set BROWSER_OUT_DIR=
set IE=
set FF=
set CHROME=
set XP=
set rawcopy=

endlocal
echo.&pause&goto:eof



REM The 2 next function produce a html file.
REM They should be called like this:
REM call:OpenHtmlFile "filename"
REM do something which outputs to the filename.html eg: echo lala >> filename.html
REM call:CloseHtmlFile "filename"



:OpenHtmlFile
set TMPHTMLFILE=%HTML_DIR%\%~1.html
echo ^<!doctype html^> > %TMPHTMLFILE%
echo ^<html^>^<head^> >> %TMPHTMLFILE%
echo ^<title^>%~1^</title^> >> %TMPHTMLFILE%
echo ^</head^> >> %TMPHTMLFILE%
echo ^<body^> >> %TMPHTMLFILE%
echo ^<pre^> >> %TMPHTMLFILE%
goto:eof

:CloseHtmlFile
set TMPHTMLFILE=%HTML_DIR%\%~1.html
echo ^</pre^> >> %TMPHTMLFILE%
echo ^</body^> >> %TMPHTMLFILE%
echo ^</html^> >> %TMPHTMLFILE%
goto:eof



:MakeIndexEntry
set INDEXHTML=%~1
set NEWFILE=%HTML_DIR%\%~2
set MENULBL=%~3
echo ^<li^>^<a href="%NEWFILE%"^>%MENULBL%^</a^>^</li^> >> %INDEXHTML%
goto:eof


:OpenIndexHtmlFile
set INDEXHTML=%~1
echo ^<!doctype html^>^<html^>^<head^>^<title^>LiveCap Results^</title^>^</head^>^<body^>^<ul^>  > %INDEXHTML%
goto:eof

:CloseIndexHtmlFile
set INDEXHTML=%~1
echo ^</ul^>^</body^>^</html^> >> %INDEXHTML%
goto:eof