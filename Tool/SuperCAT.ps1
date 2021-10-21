<###########################################################################################################
## SUPERCAT (CYBER ASSESSMENT TOOL) V2.20
## DEVELOPED BY: SSGT CLINTON REEL // CLINTON.REEL@US.AF.MIL
###########################################################################################################>
Clear-Host

###########################################################################################################
## This section loads a JSON file that has configurations already pre-set. See setup-powershell.ps1
## for additional information. After that, it grabs additional information.
###########################################################################################################

try{
    $JSONConfig = Get-Content -Path "config.json" -ErrorAction Stop | ConvertFrom-JSON
}
catch{
    Write-Error "Could not find file 'config.json' in the current directory. Use the setup-powershell.ps1 script to create this file."
    pause
    exit
}

$BaseName     = $JSONConfig.BaseName
$System1      = $JSONConfig.System1
$System2      = $JSONConfig.System2
$System3      = $JSONConfig.System3
$System4      = $JSONConfig.System4
$System5      = $JSONConfig.System5

$Location1    = $JSONConfig.Location1
$Location2    = $JSONConfig.Location2
$Location3    = $JSONConfig.Location3
$Location4    = $JSONConfig.Location4
$Location5    = $JSONConfig.Location5

$Drive        = (Get-Location).path
$GatherLogs   = "$Drive\..\GatheredLogs"
$AVLogs       = "$Drive\..\AVLogs"
$SCAPLogs     = "$Drive\..\SCAPLogs"
$EventLogs    = "$Drive\..\EventLogs"

$Date         = Get-Date -Format "yy-MM-dd"
$Win32OS      = Get-WMIObject -Class Win32_OperatingSystem
$ComputerName = $Win32OS.PSComputerName
$OSArch       = $Win32OS.OSArchitecture
###########################################################################################################

###########################################################################################################
## This snippet of code checks to see if the script is being ran as an administrator. If not, it notifies
## the user that it may not work as intended.
###########################################################################################################

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) -eq $False){
    Write-Warning "THIS SCRIPT WAS NOT RUN AS AN ADMINISTRATOR! SOME TASKS MAY NOT WORK OR PROVIDE INACCURATE RESULTS!"
}

###########################################################################################################
## The user will provide a number or numbers (0-7) and the script writes it to an array. For each number, a
## specific task sequence will be executed. If 6 is used, all tasks are performed.
###########################################################################################################
Write-Output "
===============================================================
Select from the following options, inputting only numbers and
commas (i.e. 1,3,4,5):

0 = Update Antivirus (Requires Pre-Approved Actions)

1 = Collect Computer Information
2 = Initialize Antivirus Scan
3 = Collect Antivirus Logs
4 = Initialize SCAP
5 = Collect Windows Event Logs
6 = All Tasks (Collection Only, No Antivirus Updating)

7 = Exit Program
==============================================================="
$Choices = Read-Host

while($Choices -notmatch "^[0-7,]*$"){
    $Choices = Read-Host "Please only input numbers 0 to 7 and commas (i.e. 1,3,5)"
}

$Choices = $Choices.Split(",")

###########################################################################################################
## Option 0 updates the antivirus definitions on the system to what is available on the disc, but only if
## the definitions are older.
##
## Note: This option is separated from the other tasks, for teams only looking to collect data.
###########################################################################################################

if(($Choices -Contains 0) -and ($Choices -NotContains 7)){
    Write-Output "Checking DAT Signatures..."
    $InstalledDAT = (Get-Childitem "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat").CreationTime
    $CATDAT       = (Get-Childitem "$Drive\AV\DAT\CM*").CreationTime
    $CATDATName   = (Get-Childitem "$Drive\AV\DAT\CM*").Name

    if($InstalledDAT -lt $CATDAT){
        Write-Output "Installing new DAT Signatures..." & "$Drive\AV\DAT\$CATDATName" /SILENT /F
    }
    else{
        Write-Output "Installed DAT files are more up-to-date than what is on the disc."
    }
}

###########################################################################################################
## Option 1 gathers basic information about the system, including serial number, operating system and its
## version, what type of system it is or what it is used for, and more.
###########################################################################################################

if((($Choices -Contains 1) -or ($Choices -Contains 6)) -and ($Choices -NotContains 7)){
    $SerialNumber = (Get-WMIObject -Class Win32_BIOS).SerialNumber
    $MACAddress   = (Get-WMIObject -Class Win32_NetworkAdapter | Where-Object {$Null -ne $_.MACaddress} | Select-Object -First 1).MACAddress
    $HardDrives   = Get-PhysicalDisk | Select-Object FriendlyName,Model,MediaType,BusType,HealthStatus,OperationalStatus,Usage,Size
    $OSName       = $Win32OS.Caption
    $OSVer        = $Win32OS.Version

    Write-Output "
    ===============================================================
    The serial number for this system appears to be: $SerialNumber
    Is this correct? (This may be wrong/not work on some systems.)
    1 = Yes
    2 = I'll type it myself.
    ==============================================================="

    $SerialCheck = Read-Host
    while($SerialCheck -notmatch "^[1-2]$"){
        $SerialCheck = Read-Host "You must input either 1 or 2."
    }
    if($SerialCheck -eq 2){
        $SerialNumber = Read-Host "Type the serial number you wish to input, then press Enter"
    }

    ## Adds the generic information about the machine to a file.
    Write-Output "Writing computer name, serial number, and base info..."
    Add-Content -Value "Date: $Date" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "Serial Number: $SerialNumber" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "Computer Name: $ComputerName" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "Operating System: $OSName" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "Operating System Version: $OSVer" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "Base: $BaseName" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "MAC Address: $MACAddress" -Path "$GatherLogs\$ComputerName-Info.txt"

    $HardDrives | Export-CSV -Path "$GatherLogs\$ComputerName-HardDrives.csv" -NoTypeInformation

    Write-Output "Writing hard drive information..."

    ## Based on what is in the JSON file, it writes the System names and asks the user which system
    ## the machine belongs to. Then, it writes it to file.
    Write-Output "
    ===============================================================
    What type of system is this?
    1 = $System1
    2 = $System2
    3 = $System3
    4 = $System4
    5 = $System5
    6 = Other (I will type it in)
    ==============================================================="
    $System = Read-Host

    while($System -notmatch "^[1-5]$"){
        $System = Read-Host "You must input a number between 1 and 5."
    }

    if($System -eq 1){
        Add-Content -value "System: $System1" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($System -eq 2){
        Add-Content -value "System: $System2" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($System -eq 3){
        Add-Content -value "System: $System3" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($System -eq 4){
        Add-Content -value "System: $System4" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($System -eq 5){
        Add-Content -value "System: $System5" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($Location -eq 6){
        Write-Output "Type in the System and press Enter"
        $Location6 = Read-Host
        Add-Content -value "Location: $System6" -Path "$GatherLogs\$ComputerName-Info.txt"
    }

    ## Based on what is in the JSON file, it asks for the location of the machine (or you can write it in).
    Write-Output "
    ===============================================================
    Where is this system located?
    1 = $Location1
    2 = $Location2
    3 = $Location3
    4 = $Location4
    5 = $Location5
    6 = Other (I will type it in)
    ==============================================================="
    $Location = Read-Host

    while($System -notmatch "^[1-6]$"){
        $Location = Read-Host "You must input a number between 1 and 6."
    }

    if($Location -eq 1){
        Add-Content -value "Location: $Location1" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($Location -eq 2){
        Add-Content -value "Location: $Location2" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($Location -eq 3){
        Add-Content -value "Location: $Location3" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($Location -eq 4){
        Add-Content -value "Location: $Location4" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($Location -eq 5){
        Add-Content -value "Location: $Location5" -Path "$GatherLogs\$ComputerName-Info.txt"
    }
    elseif($Location -eq 6){
        Write-Output "Type in the location and press Enter"
        $Location6 = Read-Host
        Add-Content -value "Location: $Location6" -Path "$GatherLogs\$ComputerName-Info.txt"
    }

    # Systeminfo has a lot of additional information that will be written to a file.
    Write-Output "Writing Systeminfo..."
    systeminfo > "$GatherLogs\$ComputerName-SystemInfo.txt"

    # This is a list of all of the relevant registry keys that have information about the installation of programs.
    # After it gathers these items, it queries them for application information and sends it to a .CSV.
    Write-Output "Gathering Installed Programs..."
    $AppsRegistryLocations = (
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
    )

    $Apps = Get-ChildItem $AppsRegistryLocations | Get-ItemProperty | Sort-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation,InstallDate,DisplayIcon,URLInfoAbout,EstimatedSize

    Write-Output "Found $($Apps.count) applications. Writing to CSV..."
    $Apps | Export-CSV -NoTypeInformation -Path "$GatherLogs\$ComputerName-Programs.csv"

    # Gathers information on the local users (are they active? are they disabled? are they locked? what accounts are available?)
    Write-Output "Writing local users..."
    Get-LocalUser | Select-Object Name,Enabled,PasswordRequired,PasswordExpires,LastLogon,SID | Export-CSV -NoTypeInformation -Path "$GatherLogs\$ComputerName-Accounts.csv"

    # Gathers the open ports and active connections currently on the machine and writes to a .CSV.
    Write-Output "Writing open ports..."
    Get-NetTCPConnection | Export-CSV -NoTypeInformation -Path "$GatherLogs\$ComputerName-Ports.csv"

    # Gathers the current services and sends it to a CSV.
    Write-Output "Writing current processes..."
    Get-Service | Select-Object Name,ServiceName,DisplayName,Status | Export-CSV -NoTypeInformation -Path "$GatherLogs\$ComputerName-Services.csv"
}

###########################################################################################################
## Option 2 runs an antivirus scan on the machine, sending its logs to folder the script was executed from (i.e. CD).
###########################################################################################################

if((($Choices -Contains 2) -or ($Choices -Contains 6)) -and ($Choices -NotContains 7)){
    # Conducts a scan on the machine.
    Write-Output "Running antivirus scan..."
    if($OSArch -eq "64-bit"){
        .$Drive\AV\w64\SCAN /DRIVER=$Drive\AV\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$AVLogs\$ComputerName-AV-Report.txt /HTML $AVLogs\$ComputerName-AVREPORT.html
    }
    else{
        .$Drive\AV\w32\SCAN /DRIVER=$Drive\AV\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$AVLogs\$ComputerName-AV-Report.txt /HTML $AVLogs\$ComputerName-AVREPORT.html
    }
}

###########################################################################################################
## Option 3 sends any available antivirus logs to the location of the script (i.e. CD).
###########################################################################################################

if((($Choices -Contains 3) -or ($Choices -Contains 6)) -and ($Choices -NotContains 7)){
    # Gathers scan logs already on the machine.
    Write-Output "Gathering scan logs..."
    if($Win32Caption -like "*Windows 7*"){
        Copy-Item -Path "C:\ProgramData\McAfee\DestkopProtection\OnDemandScanLog.txt" -Destination "$AVLogs"
    }
    else{
        Copy-Item -Path "C:\ProgramData\McAfee\Endpoint Security\Logs\" -Destination "$AVLogs" -Recurse
    }
}

###########################################################################################################
## Option 4 runs the DISA SCAP tool to check on the system's STIG compliance, send it back for analysis.
###########################################################################################################

if((($Choices -Contains 4) -or ($Choices -Contains 6)) -and ($Choices -NotContains 7)){
    # Conducts a SCAP check on the machine and writes it to a file.
    if(test-path "$Drive\DISA\cscc.exe"){
        Write-Output "Running SCAP Scan..."
        & $Drive\DISA\cscc.exe -u $SCAPLogs
    }

    Write-Output "Moving SCAP results to easier to access folder..."
    Move-Item -Path "$Drive\Results\" -Destination "$SCAPLogs"
}

###########################################################################################################
## Option 5 gathers Windows Events logs and sends it to the location of the script (CD).
###########################################################################################################

if((($Choices -Contains 5) -or ($Choices -Contains 6)) -and ($Choices -NotContains 7)){
    # Attempts to copy the Windows event logs to the disc for further analysis later.
    New-Item -ItemType Directory -Path "$EventLogs" | Out-Null
    Write-Output "Exporting Windows event logs to .evtx..."

    wevtutil.exe epl System "$EventLogs\$ComputerName-System.evtx"
    wevtutil.exe epl Security "$EventLogs\$ComputerName-Security.evtx"
    wevtutil.exe epl Application "$EventLogs\$ComputerName-Application.evtx"
}

###########################################################################################################
## Option 7 exits the program completely.
###########################################################################################################

if ($Choices -Contains 7){
    Write-Output "No files have been transferred..."
    Write-Output "Exiting tool..."
    pause
    exit
}

###########################################################################################################
## Final clean-up of files on the disc. This will only run if options 1 to 6 are selected.
###########################################################################################################

if ($Choices -match "^[1-6]$"){
    Write-Output "
    ===============================================================
    Assessment is completed!
    Would you like to remove extra files/programs on $Drive ?
    (This is useful if you are finalizing the disc.)
    1 = Yes
    2 = No
    ==============================================================="
    $RemoveExtras = Read-Host

    while($RemoveExtras -notmatch "^[1-2]$"){
        $RemoveExtras = Read-Host "You must input either 1 or 2."
    }

    if($RemoveExtras -eq 1){
        # Cleans up the disc of files no longer required.
        Write-Output "Cleaning up extras..."
        Remove-Item -Path "$Drive" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "$Drive\..\Export" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "$Drive\..\setup-powershell.ps1" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "$Drive\..\setup-batch.bat" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "$Drive\..\ReleaseNotes.txt" -Recurse -ErrorAction SilentlyContinue
    }
}

Write-Output "Done!"
pause