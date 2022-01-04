#!/bin/pwsh

<###############################################################################
## SUPERCAT (CYBER ASSESSMENT TOOL) V2.20
## DEVELOPED BY: SSGT CLINTON REEL // CLINTON.REEL@US.AF.MIL
## ADDITIONAL DEVELOPERS IN CONTRIBUTORS.TXT
###############################################################################>

######################### Module Imports #######################################

$ScriptDirectory = $MyInvocation.MyCommand.Path | Split-Path

Import-Module -Force "$ScriptDirectory\Modules\Internal\Support\support.psm1"

######################### Function Declaration #################################

function Import-Config {
    # .SYNOPSIS
    # Pull config object from file. Generates skeleton if necessary.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$File
    )

    if (Test-Path -Path $File -PathType Leaf) {
        Write-Debug "The file $File exists."
        Try {
            return $(Import-Clixml -ErrorAction Stop -Path $File)
        }
        Catch {
            throw "The file $File incorrectly formated. Please check and fix formatting errors or delete."
        }
    }
    elseif ( Test-Path -Path $File -PathType Container ) {
        throw "$File is a directory!"
    }
    else {
        Write-Host "The file $File `ndoes not exist. Would you like to continue?"
        if ( !$(Read-Intent -TF) ) {
            Write-Host "Exiting! No changes have been made."
            exit
        }
        return [PSCustomObject]@{
            ConfigVersion       = [System.Version]"2.0.0"
            CreationTimeUTC     = Get-ActualDate
            LastAccessTimeUTC   = Get-ActualDate
            LastWriteTimeUTC    = Get-ActualDate
            LastHDD             = ''
            BaseName            = Read-Host -Prompt "What installation is serviced by your organization"
            ScanningOrg         = Read-Host -Prompt "What is your organization"
            KnownDrives         = @{}
        }
    }
}

function Update-Config {
    # .SYNOPSIS
    # Update config object, adding drive config if it doesn't exist.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [PSCustomObject]$Config
    )
    function Read-SystemType {      ## TODO: Replace w/ autopull when developed
        $SelectionArray = @(
            "CAPRE",
            "VIPER",
            "Other"
        )
        switch ($(Read-Intent $SelectionArray "What type of system is this?")) {
            $SelectionArray[0] { return $SelectionArray[0] }
            $SelectionArray[1] { return $SelectionArray[1] }
            $SelectionArray[2] { return $(Read-Host -Prompt "What type of system is this") }
        }
    }
    function Read-Classification {      ## TODO: Replace w/ autopull when developed
        $SelectionArray = @(
            "Unclassified",
            "Confidential",
            "Secret",
            "Top Secret",
            "Other"
        )
        switch ($(Read-Intent $SelectionArray "What is the classification?")) {
            $SelectionArray[0] { return $SelectionArray[0] }
            $SelectionArray[1] { return $SelectionArray[1] }
            $SelectionArray[2] { return $SelectionArray[2] }
            $SelectionArray[3] { return $SelectionArray[3] }
            $SelectionArray[4] { return $(Read-Host -Prompt "What is the classification") }
        }
    }
    $LocalDrive = (Get-WMIObject Win32_PhysicalMedia |
      Where-Object {$_.Tag -eq "\\.\PHYSICALDRIVE0"}).SerialNumber
    $Config.LastAccessTimeUTC = Get-ActualDate
    if ( $Config.KnownDrives.Keys -NotContains $LocalDrive ) {
        Write-Host "Unknown drive. Would you like to add this `ndrive to the database?"
        if ( !$(Read-Intent -TF) ) {
            Write-Host
            Write-Host "Exiting! Nothing has been written."
            exit
        }
        Write-Host "Adding drive to database."
        Write-Host
        $Config.KnownDrives.$LocalDrive = @{
            CreationTimeUTC     = Get-ActualDate
            LastAccessTimeUTC   = Get-ActualDate
            LastWriteTimeUTC    = Get-ActualDate
            DriveName           = Read-Host -Prompt "What is this HDD called"
            SystemType          = Read-SystemType
            Unit                = Read-Host -Prompt "What unit does this HDD belong to"
            Classification      = Read-Classification
        }
        Write-Host
        Write-Host "Complete!"
        pause
        #  Clear-Host
    }
    while ($True) {
        Write-Host "
            Base Name         = $($Config.BaseName)
            Organization      = $($Config.ScanningOrg)
            Drive Name        = $($Config.KnownDrives.$LocalDrive.DriveName)
            System Type       = $($Config.KnownDrives.$LocalDrive.SystemType)
            Serviced Unit     = $($Config.KnownDrives.$LocalDrive.Unit)
            Classification    = $($Config.KnownDrives.$LocalDrive.Classification)"
        Write-Host "Is this information correct?"
        if ($(Read-Intent -TF)) { break }
        $Config.KnownDrives.$LocalDrive.LastWriteTimeUTC = Get-ActualDate
        $Config.LastWriteTimeUTC = Get-ActualDate
        $SelectionArray = @(
            "Base Name",
            "Organization",
            "Drive Name",
            "System Type",
            "Serviced Unit",
            "Classification"
        )
        switch($(Read-Intent $SelectionArray "What should be changed?")) {
            $SelectionArray[0] {$Config.BaseName                                 = Read-Host -Prompt "Base Name"}
            $SelectionArray[1] {$Config.ScanningOrg                              = Read-Host -Prompt "Organization"}
            $SelectionArray[2] {$Config.KnownDrives[$LocalDrive].DriveName       = Read-Host -Prompt "Drive Name"}
            $SelectionArray[3] {$Config.KnownDrives[$LocalDrive].SystemType      = Read-SystemType}
            $SelectionArray[4] {$Config.KnownDrives[$LocalDrive].Unit            = Read-Host -Prompt "Serviced Unit"}
            $SelectionArray[5] {$Config.KnownDrives[$LocalDrive].Classification  = Read-Classification}

            Default {throw "Update-Config -> if known drive -> switch fell through."}
        }

    }
    $Config.KnownDrives.$LocalDrive.LastAccessTimeUTC = Get-ActualDate
    $Config.LastHDD = $LocalDrive
    return $Config
}

function Export-Config {
    #.SYNOPSIS
    # Write config object to file.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=1)]
        [PSCustomObject]$Config,
        [Parameter(Mandatory=$True,Position=0)]
        [String]$File,
        [Parameter()]
        [switch]$PassThru
    )
    #$Config | Select-Object -ExcludeProperty 'LastHDD' -Property * |
    #  Export-Clixml -Depth 10 -Force -Path $File | Out-Null
    $Config | Export-Clixml -Depth 10 -Force -Path $File | Out-Null
    if ($PassThru) {
        return $Config
    }
    else{
        return $True
    }
}

function Update-Signatures ([String]$RootDirectory) {
    # .SYNOPSIS
    # Update antivirus definitions.

    <#
    .DESCRIPTION
       Updates the antivirus definitions on the system to what is available
       on the disc, but only if the definitions are older.

       Note: This option is separated from the other tasks, for teams only
        looking to collect data.
    #>


    ##TODO: Handle multiple signatures and validate file type.
    Write-Host "Checking DAT Signatures..."
    $InstalledDAT = (Get-Childitem "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat").CreationTime
    $CATDAT       = (Get-Childitem "$RootDirectory\AV\DAT\CM*").CreationTime
    $CATDATName   = (Get-Childitem "$RootDirectory\AV\DAT\CM*").Name

    if($InstalledDAT -lt $CATDAT){
        Write-Host "Installing new DAT Signatures..."
        Start-Process -FilePath "$RootDirectory\AV\DAT\$CATDATName" `
          -ArgumentList "/SILENT /F"
    }
    else{
        Write-Host "Installed DAT files are more up-to-date than what is on the disc."
    }
}

function Import-Identifiers ([PSCustomObject]$Config,[String]$LogPrefix) {
    if (!$(Test-Path $($LogPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($LogPrefix | Split-Path) | Out-Null }
    $Win32OS            = Get-WMIObject -Class Win32_OperatingSystem
    $BaseName     = $Config.BaseName
    $LogPath      = "$LogPrefix-Info.txt"
    Write-Host $LogPath.gettype()
    Write-Host $LogPath
    $OSName       = $Win32OS.Caption
    $OSVer        = $Win32OS.Version
    $PSVersion    = Get-Host | Select-Object Version
    ## TODO: Find a unique ID for the chasis
    $ChasisSerialNumber = (Get-WMIObject -Class Win32_BIOS).SerialNumber
    $MACAddress   = (Get-WMIObject -Class Win32_NetworkAdapter |
      Where-Object {$Null -ne $_.MACaddress} |
      Select-Object -First 1).MACAddress

    ## Adds the generic information about the machine to a file.
    Write-Output "Writing computer name, serial number, and base info..."
    Add-Content -Value "Date: $(Get-ActualDate)" -Path $LogPath
    Add-Content -Value "PowerShell Version: $PSVersion" -Path "$GatherLogs\$ComputerName-Info.txt"
    Add-Content -Value "Serial Number: $ChasisSerialNumber" -Path $LogPath
    Add-Content -Value "Computer Name: $($Win32OS.PSComputerName)" -Path $LogPath
    Add-Content -Value "Operating System: $OSName" -Path $LogPath
    Add-Content -Value "Operating System Version: $OSVer" -Path $LogPath
    Add-Content -Value "Base: $BaseName" -Path $LogPath
    Add-Content -Value "MAC Address: $MACAddress" -Path $LogPath

    if ((Get-Host).Version.Major -gt 2) {
        Get-PhysicalDisk |
          Select-Object FriendlyName,Model,MediaType,BusType,HealthStatus,
            OperationalStatus,Usage,Size |
          Export-CSV -Path "$LogPrefix-HardDrives.csv" `
            -NoTypeInformation
    }
    
    # Systeminfo has a lot of additional information that will be written to a file.
    Write-Host "Writing Systeminfo..."
    systeminfo > "$LogPrefix-SystemInfo.txt"

    # This is a list of all of the relevant registry keys that have information about the installation of programs.
    # After it gathers these items, it queries them for application information and sends it to a .CSV.
    Write-Host "Gathering Installed Programs..."
    $AppsRegistryLocations = (
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
    )

    ##TODO: Why does this not work on Win7
    $Apps = Get-ChildItem $AppsRegistryLocations | Get-ItemProperty |
      Sort-Object DisplayName |
      Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation,
        InstallDate,DisplayIcon,URLInfoAbout,EstimatedSize

    Write-Host "Found $($Apps.count) applications. Writing to CSV..."
    $Apps | Export-CSV -NoTypeInformation -Path "$LogPrefix-Programs.csv"

    # Gathers information on the local users
    # Are they active? Are they disabled? Are they locked?
    # What accounts are available?
    Write-Host "Writing local users..."
    Get-LocalUser | Select-Object Name,Enabled,PasswordRequired,PasswordExpires,
        LastLogon,SID | Export-CSV -NoTypeInformation -Path "$LogPrefix-Accounts.csv"

    # Gathers the open ports and active connections currently on the machine and writes to a .CSV.
    Write-Host "Writing open ports..."
    Get-NetTCPConnection |
        Export-CSV -NoTypeInformation -Path "$LogPrefix-Ports.csv"

    # Gathers the current services and sends it to a CSV.
    Write-Host "Writing current processes..."
    Get-Service | Select-Object Name,ServiceName,DisplayName,Status |
        Export-CSV -NoTypeInformation -Path "$LogPrefix-Services.csv"
}

function Start-Antivirus ([String]$RootDirectory, [String]$LogPrefix) {
    <#
    .SYNOPSIS
       Runs an antivirus scan on the machine, sending any available antivirus logs
       to the location of the script.
    #>
    if (!$(Test-Path $($LogPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($LogPrefix | Split-Path) | Out-Null }
    Write-Host "Running antivirus scan..."
    if($(Get-WMIObject -Class Win32_OperatingSystem).OSArchitecture -eq "64-bit"){
        Start-Process -FilePath "$RootDirectory\AV\w64\SCAN" -ArgumentList "/DRIVER=$RootDirectory\AV\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$LogPrefix-AV-Report.txt /HTML $LogPrefix-AVREPORT.html"
    }
    else{
        Start-Process -FilePath "$RootDirectory\AV\w32\SCAN" -ArgumentList "/DRIVER=$RootDirectory\AV\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$LogPrefix-AV-Report.txt /HTML $LogPrefix-AVREPORT.html"
    }
}

function Import-AntivirusLogs ([String]$Directory) {
    # .SYNOPSIS
    # Sends any available antivirus logs to the location of the script.
    if (!$(Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null}
    Write-Host "Gathering scan logs..."
    if($Win32Caption -like "*Windows 7*"){
        Copy-Item -Path "C:\ProgramData\McAfee\DestkopProtection\OnDemandScanLog.txt" -Destination "$Directory"
    }
    else{
        Copy-Item -Path "C:\ProgramData\McAfee\Endpoint Security\Logs\" -Destination "$Directory" -Recurse
    }
}

function Start-SCAP ([String]$RootDirectory, [String]$Directory) {
    # .SYNOPSIS
    # Conducts a SCAP check on the machine and writes it to a file

    if (!$(Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null }
    if(test-path "$RootDirectory\DISA\cscc.exe"){
        Write-Host "Running SCAP Scan..."
        Start-Process -FilePath "$RootDirectory\DISA\cscc.exe" -ArgumentList "-u $Directory"
    }

    Write-Host "Moving SCAP results to easier to access folder..."
    Move-Item -Path "$RootDirectory\Results\" -Destination "$Directory"
}

function Import-EventLogs ([String]$LogPrefix) {
    # .SYNOPSIS
    # Gathers Windows Events logs and sends it to the location of the script

    if (!$(Test-Path $($LogPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($LogPrefix | Split-Path) | Out-Null }
    Write-Host "Exporting Windows event logs to .evtx..."

    wevtutil.exe epl System "$LogPrefix-System.evtx"
    wevtutil.exe epl Security "$LogPrefix-Security.evtx"
    wevtutil.exe epl Application "$LogPrefix-Application.evtx"
}


################################ General ######################################
#  Clear-Host

## Check for administrative privildges, warn in necessary, continue
$isAdmin = ([Security.Principal.WindowsPrincipal](
  [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if($isAdmin -eq $False){
    Write-Warning "THIS SCRIPT WAS NOT RUN AS AN ADMINISTRATOR! SOME TASKS MAY NOT WORK OR PROVIDE INACCURATE RESULTS!"
}

## Get current time from user. We can't trust the system time b/c dead CMOS.
## This is utilized by the Get-ActualDate supporting fucntion.
$UserTime = Get-TimeDelta

# Main Loop

$Config = Import-Config "$ScriptDirectory\config.xml" | Update-Config | Export-Config "$ScriptDirectory\config.xml" -PassThru
while ($True) {
    $Options = @(
        "Update Antivirus (Requires Pre-Approved Actions)",
        "Collect Computer Information",
        "Initialize Antivirus Scan",
        "Collect Antivirus Logs",
        "Initialize SCAP",
        "Collect Windows Event Logs",
        "All Tasks (Collection Only, No Antivirus Updating)",
        "Exit Program"
    )
    $Choices = Read-Intent $Options -Multiple -Prompt "Please select from the following."
    switch($Choices) {
        $Options[0] { Update-Signatures $ScriptDirectory }
        $Options[1] { Import-Identifiers $Config "$ScriptDirectory\..\..\Outputs\GatheredLogs\$($Config.LastHDD)-$(Get-ActualDate)" }
        $Options[2] { Start-Antivirus $ScriptDirectory "$ScriptDirectory\..\..\Outputs\AVLogs\$($Config.LastHDD)-$(Get-ActualDate)" }
        $Options[3] { Import-AntivirusLogs "$ScriptDirectory\..\..\Outputs\AVLogs" }
        $Options[4] { Start-SCAP $ScriptDirectory "$ScriptDirectory\..\..\Outputs\SCAPLogs" }
        $Options[5] { Import-EventLogs "$ScriptDirectory\..\..\Outputs\EventLogs\$($Config.LastHDD)-$(Get-ActualDate)"}
        $Options[6] {
            Import-Identifiers $Config "$ScriptDirectory\..\..\Outputs\GatheredLogs\$($Config.LastHDD)-$(Get-ActualDate)"
            Import-Antivirus $ScriptDirectory "$ScriptDirectory\..\..\Outputs\AVLogs\$($Config.LastHDD)-$(Get-ActualDate)"
            Start-SCAP $ScriptDirectory "$ScriptDirectory\..\..\Outputs\SCAPLogs"
            Import-EventLogs "$ScriptDirectory\..\..\Outputs\EventLogs\$($Config.LastHDD)-$(Get-ActualDate)"
        }
        $Options[7] {
            Write-Host "Exiting!"
            exit
        }
        Default {
            Write-Host "Please only input numbers 0 to 7 and commas (i.e. 1,3,5)"
            Write-Host "Recieved Input $_"
        }
    }
}
