::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: CYBER ASSESSMENT TOOL V2.01 - BATCH EDITION
:: ORIGINALLY DEVELOPED BY:
:: RECODED BY: SSGT CLINTON REEL // CLINTON.REEL@US.AF.MIL
::
:: v2.00 - Rewrote large portions of the script to make it more intuitive
::
:: v2.01 - Added calls for a .TXT file for configurations.
::       - Added an external script to create the .TXT file.
::       - Added an external PowerShell script to query collected .EVTX files.
::       - Added an external PowerShell script to query collected .REG files.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
CLS
SETLOCAL EnableDelayedExpansion

FOR /F "delims=" %%X in (config.txt) DO (SET "%%X")

SET DRIVE=%~dp0
SET LOGS=%~dp0\Logs

:: Grabs some quick information about the  computer through WMIC.
FOR /F "tokens=2 delims==" %%A in ('WMIC OS GET CSNAME /VALUE ^| FIND "="') DO SET _ComputerName=%%A
FOR /F "tokens=2 delims==" %%A in ('WMIC OS GET CAPTION /VALUE ^| FIND "="') DO SET _OSName=%%A
FOR /F "tokens=2 delims==" %%A in ('WMIC OS GET OSARCHITECTURE /VALUE ^| FIND "="') DO SET _OSArch=%%A
FOR /F "tokens=2 delims==" %%A in ('WMIC OS GET VERSION /VALUE ^| FIND "="') DO SET _OSVer=%%A
FOR /F "tokens=2 delims==" %%A in ('WMIC BIOS GET SERIALNUMBER /VALUE ^| FIND "="') DO SET _SerialNumber=%%A

:Begin
cls
ECHO ===============================================================
ECHO Please select one or more of the following options, with a
ECHO comma separating each choice (i.e. 1,2,3,4).
ECHO 1 = Collect Computer Information
ECHO 2 = Update Antivirus
ECHO 3 = Initialize Antivirus Scan
ECHO 4 = Collect Antivirus Logs
ECHO 5 = Initialize SCAP
ECHO 6 = Collect Windows Event Logs
ECHO 7 = All Tasks
ECHO ===============================================================
SET /P _Choices=

:: Quick check to make sure you put in a number between 1 and 7.
:: If the user didn't, it will go back to the prompt.
ECHO.%_Choices% | findstr -v "1 2 3 4 5 6 7">nul &&(
    GOTO :Begin
)

:: If 7 is inputted, _Choices is set to 1,2,3,4,5,6. This means all
:: task sequences will be conducted.
FOR %%a in (%_Choices%) DO (
    IF %%a EQU 7 (
        SET _Choices=1,2,3,4,5,6
    )
)

FOR %%i in (%_Choices%) DO (
    CALL :Option-%%i
)

SET _OS=WMIC OS GET CAPTION /VALUE

:Option-1

:SerialNumber
ECHO ===============================================================
ECHO The serial number for this system appears to be: %_SerialNumber%
ECHO Is this correct? This may not work for all systems.
ECHO 1 = Yes
ECHO 2 = I'll type it myself.
ECHO ===============================================================
SET /P _SN=

ECHO.%_SN% | findstr -v "1 2">nul &&(
    GOTO :SerialNumber
)

:: Exports the serial number of the machine to a file.
IF %_SN%==1 (
    ECHO Date: %DATE:~10,4%%DATE:~4,2%%DATE:~7,2% > %DRIVE%\%ComputerName%_%_SerialNumber%.txt
    ECHO Serial Number: %_SerialNumber% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_SN%==2 (
    SET /p _SerialNumber="Type the correct serial number, then press enter:"
    ECHO Date: %DATE:~10,4%%DATE:~4,2%%DATE:~7,2% > %DRIVE%\%ComputerName%_!_SerialNumber!.txt
    ECHO Serial Number: !_SerialNumber! >> %DRIVE%\%ComputerName%_!_SerialNumber!.txt
)

ECHO Writing computer name...
ECHO Computer Name: %ComputerName% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt

:System_Function
ECHO ===============================================================
ECHO What type of system is this?
ECHO 1 = %_System1%
ECHO 2 = %_System2%
ECHO 3 = %_System3%
ECHO 4 = %_System4%
ECHO 5 = %_System5%
ECHO ===============================================================
SET /P _System=

ECHO.%_System% | findstr -v "1 2 3 4 5">nul &&(
    GOTO :System_Function
)

IF %_System%==1 (
    ECHO System: %_System1% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_System%==2 (
    ECHO System: %_System2% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_System%==3 (
    ECHO System: %_System3% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_System%==4 (
    ECHO System: %_System4% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_System%==5 (
    ECHO System: %_System5% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)

:Location

:: Imported form the .txt file, Locations are loaded and the user can select any
:: of them or type their own in. Afterwards, it is exported to file.
ECHO ===============================================================
ECHO Where is this system located?
ECHO 1 = %_Location1%
ECHO 2 = %_Location2%
ECHO 3 = %_Location3%
ECHO 4 = %_Location4%
ECHO 5 = %_Location5%
ECHO 6 = Other (I will type it in)
ECHO ===============================================================
SET /P _Location=

ECHO.%_Location% | findstr -v "1 2 3 4 5 6">nul &&(
    GOTO :Location
)

IF %_Location%==1 (
    ECHO Location: %_Location1% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_Location%==2 (
    ECHO Location: %_Location1% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_Location%==3 (
    ECHO Location: %_Location1% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_Location%==4 (
    ECHO Location: %_Location1% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_Location%==5 (
    ECHO Location: %_Location1% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)
IF %_Location%==6 (
    SET /P _Location6="Type in the location and press Enter:"
    ECHO Location: %_Location6% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt 
)

ECHO Writing Systeminfo...
ECHO. >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
ECHO ************************************************************************* >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
ECHO System Information on %ComputerName% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
systeminfo >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt

ECHO ************************************************************************* >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
ECHO Writing local users...
cscript //nologo %DRIVE%\Scripts\Accounts.vbs > %DRIVE%\%ComputerName%_%_SerialNumber%_Accounts.csv

ECHO Writing installed programs to csv...
:: Collects the registry keys used for installed programs to .HIV files. Afterwards, the operator
:: would use export-offline-registry to export relevant application data to a .CSV.
ECHO Exporting software registry keys to file...
reg save "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" "HKLM-32bit.hiv"
reg save "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" "HKCU-32bit.hiv"
reg save "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" "HKLM-64bit.hiv"

ECHO Writing ports, protocols, processes, and services...
:: Collect ports on the computer and format it for a CSV.
cscript //nologo %DRIVE%\Scripts\Ports.vbs >> %DRIVE%\_Ports.csv
ECHO ************************************************************************* >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
ECHO Open Ports on %ComputerName% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
NETSTAT -AON >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
(
    FOR /F "tokens=1,2,3,4 delims=," %%a in (%DRIVE%\_Ports.csv) do (
        setlocal enabledelayedexpansion
        SET /p line= 
        ECHO(%%a,%%b,%%c,%%d!line!
            endlocal
        )
    )
) < %DRIVE%\_Services.csv >> %DRIVE%\%ComputerName%_%_SerialNumber%_PortsServices.csv

:: Run the TASKLIST command and format it for a CSV.
TASKLIST /SVC /FO "CSV" >> %DRIVE%\_Service.csv
FOR /F "tokens=1,2,* skip=1 delims=," %%A in (%DRIVE%\_Service.csv) DO ECHO %%~C >> %DRIVE%\_Serv.csv
FOR /F "delims==" %%a in (%DRIVE%\_Serv.csv) DO SET string=%%a & ECHO !string:,=;! >> %DRIVE%\_Services.csv

:: Collect running processes and write them to a CSV.
ECHO Running processes on %ComputerName% >> %DRIVE%\%ComputerName%_%_SerialNumber%.txt
wmic process list /format:CSV >> %DRIVE%\_Servs.csv
FOR /F "tokens=2,3 skip=1 delims=," %%a IN (%DRIVE%\_Servs.csv) DO ECHO %%a,%%b >> %DRIVE%\%ComputerName%_%_SerialNumber%_Services.csv

:Option-2
IF NOT EXIST "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat" GOTO :Option-3
IF EXIST "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat" (
    ECHO ************************************************************************* >> %DRIVE%\%computername%_%_SerialNumber%.txt
    ECHO Virus Scanning Software Installed on %computername% >> %DRIVE%\%computername%_%_SerialNumber%.txt
    wmic /namespace:\\root\securitycenter2 path antivirusproduct get displayname | findstr McAfee >> %DRIVE%\%computername%_%_SerialNumber%.txt
    FOR /F "delims=" %%a IN ('CSCRIPT //NOLOGO %DRIVE%\Scripts\Date.vbs "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat"') DO SET _AV_Date=%%a
    FOR /F "delims=" %%a IN ('CSCRIPT //NOLOGO %DRIVE%\Scripts\Date.vbs %DRIVE%\AV\DAT\CM-237075-9181xdat.exe') DO SET _NEW_AV_Date=%%a
    ECHO ********************************************************************************
    ECHO ********************************************************************************
    ECHO ********************************************************************************
    ECHO ********************************************************************************
    ECHO *****     McAfee Virus Scanning Software Detected.                         *****
    ECHO *****     Your Virus Definitions are dated !_AV_Date!                      ***** 
    ECHO *****                                                                      *****
    ECHO *****     This DVD can update the definitions as of !_NEW_AV_Date!             ***** 
    ECHO *****                                                                      *****
    ECHO *****     Do you want to update the DAT files now?                         *****
    ECHO *****     1 = Yes. Install new virus definitions to this computer.         *****
    ECHO *****     2 = No. Leave the old virus definitions on this computer.        *****
    ECHO ********************************************************************************
    ECHO ********************************************************************************
    ECHO ********************************************************************************
    ECHO ********************************************************************************
)
SET /P _DAT=

ECHO.%_Location% | findstr -v "1 2">nul &&(
    GOTO :Option-2
)

IF %_DAT%==2 (
    CSCRIPT //NOLOGO %DRIVE%\Scripts\Date.vbs "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat" >> %DRIVE%\%computername%_%_SerialNumber%.txt
)
IF %_DAT%==1 (
    CLS
    ECHO Copying new DAT files to this computer...
    FOR /R "%DRIVE%\AV\DAT\" %%a IN (CM-237075-9181xdat.exe) DO %%~fa /SILENT /F
    CSCRIPT //NOLOGO %DRIVE%\Scripts\Date.vbs "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat" >> %DRIVE%\%computername%_%_SerialNumber%.txt
)

:Option-3
ECHO Running a virus scan with McAfee Antivirus...
IF %_OSArch%==64-bit (
    %DRIVE%\AV\w64\SCAN /DRIVER=%DRIVE%AV\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=%DRIVE%\%computername%_%_SerialNumber%_AV_Report.txt /HTML %DRIVE%\%computername%_%_SerialNumber%_AV_Report.html
    GOTO :EXIT
)
IF %_OSArch%==32-bit (
    %DRIVE%\AV\w32\SCAN /DRIVER=%DRIVE%AV\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=%DRIVE%\%computername%_%_SerialNumber%_AV_Report.txt /HTML %DRIVE%\%computername%_%_SerialNumber%_AV_Report.html
)


:Option-4
COPY C:\ProgramData\McAfee\DesktopProtection\OnDemandScanLog.txt %DRIVE%\%computername%_%_SerialNumber%_AV_Report.txt
IF EXIST %DRIVE%\%computername%_%_SerialNumber%_AV_Report.txt (
    ECHO McAfee Antivirus logs have been exported...
)
IF NOT EXIST %DRIVE%\%computername%_%_SerialNumber%_AV_Report.txt  (
    ECHO Copying the McAfee Antivirus scans failed! Is the location correct?
)

:Option-5
IF EXIST %DRIVE%\DISA\cscc.exe (
    ECHO Running the SCAP tool...
    %DRIVE%\DISA\cscc.exe -u %DRIVE%
)
IF NOT EXIST %DRIVE%\DISA\cscc.exe  (
    ECHO Could not find the SCAP tool on the disc!
)

ECHO SCAP scan completed... Writing CSVs...
MOVE %DRIVE%Results\"%date:~10,4%*" %DRIVE%Results\SCAP
MOVE %DRIVE%Results\SCAP\SCAP %DRIVE%
MOVE %DRIVE%Results\SCAP\SCC*.html %DRIVE%
REN %DRIVE%SCC*.html %computername%_%_SerialNumber%_SCAP_Scan.html
FINDSTR "StreamName:" %DRIVE%SCAP\*All-Settings*.txt >>%DRIVE%\_SCAP.csv
ATTRIB %DRIVE%\_SCAP.csv +h
FINDSTR "Adjusted" %DRIVE%SCAP\*All-Settings*.txt>>%DRIVE%\_SCAP1.csv
ATTRIB %DRIVE%\_SCAP1.csv +h
IF EXIST %DRIVE%\_SCAP.csv FOR /F "tokens=7 delims=:" %%A in (%DRIVE%\_SCAP.csv) DO ECHO %%A >> %DRIVE%\_SCAP2.csv
ATTRIB %DRIVE%\_SCAP2.csv +h
IF EXIST %DRIVE%\_SCAP1.csv FOR /F "tokens=5 delims=: " %%A in (%DRIVE%\_SCAP1.csv) DO ECHO %%A>>%DRIVE%\_SCAP3.csv 
ATTRIB %DRIVE%\_SCAP3.csv +h
IF EXIST %DRIVE%\_SCAP2.csv FOR /F "tokens=1,2,3,4 delims= " %%A in (%DRIVE%\_SCAP2.csv) DO ECHO %%A %%B %%C>>%DRIVE%\_SCAP4.csv
ATTRIB %DRIVE%\_SCAP4.csv +h
(
    FOR /F "tokens=*" %%a in (%DRIVE%\_SCAP4.csv) do (
        setlocal enabledelayedexpansion
        SET /p line= 
        ECHO(%%a,!line!
            endlocal
        )
    ) < %DRIVE%\_SCAP3.csv>> %DRIVE%\%computername%_%_SerialNumber%_SCAP.csv
)
RD /S /Q %DRIVE%\Results >nul 2>&1
RD /S /Q %DRIVE%Results >nul 2>&1
IF EXIST %LOGS% RD /S /Q %LOGS% >nul 2>&1
DEL /A /S /Q /F %DRIVE%\_*.csv >nul 2>&1
DEL /A /S /Q /F %DRIVE%_*.csv >nul 2>&1


:Option-6
ECHO Collecting Windows event logs...
ECHO Note: This may not work without administrator privileges.

IF NOT EXIST %LOGS% MD %LOGS%

IF NOT EXIST %LOGS%\%computername%_%_SerialNumber%_System.evtx (
    WEVTUtil epl System %LOGS%\%computername%_%_SerialNumber%_System.evtx
)
IF NOT EXIST %LOGS%\%computername%_%_SerialNumber%_Application.evtx (
    WEVTUtil epl Application %LOGS%\%computername%_%_SerialNumber%_Application.evtx
)
IF NOT EXIST %LOGS%\%computername%_%_SerialNumber%_Security.evtx (
    WEVTUtil epl Security %LOGS%\%computername%_%_SerialNumber%_Security.evtx
)

ECHO Assessment completed!
ECHO Cleaning up data on the disc...
IF EXIST %DRIVE%\DISA RD /S /Q %DRIVE%\DISA >nul 2>&1
IF EXIST %DRIVE%DISA RD /S /Q %DRIVE%DISA >nul 2>&1
IF EXIST %DRIVE%\AV RD /S /Q %DRIVE%\AV >nul 2>&1
IF EXIST %DRIVE%AV RD /S /Q %DRIVE%AV >nul 2>&1
IF EXIST %DRIVE%\Scripts RD /S /Q %DRIVE%\Scripts >nul 2>&1
IF EXIST %DRIVE%Scripts RD /S /Q %DRIVE%Scripts >nul 2>&1
START /b "" cmd /c DEL %DRIVE%config.txt
START /b "" cmd /c DEL %DRIVE%CAT.bat

ECHO Done!
pause
EXIT