#!/bin/pwsh

<###############################################################################
## SUPERCAT (CYBER ASSESSMENT TOOL) V0.3.3
## DEVELOPED BY: SSGT CLINTON REEL // CLINTON.REEL@US.AF.MIL
## ADDITIONAL DEVELOPERS IN CONTRIBUTORS.TXT
###############################################################################>

######################### Module Imports #######################################
using namespace System.Collections.Generic

$ScriptDirectory = $MyInvocation.MyCommand.Path | Split-Path

Import-Module -Force "$ScriptDirectory\Modules\Support.psm1" #Mandatory

Import-Module -Force "$ScriptDirectory\Modules\Antivirus.psm1"
Import-Module -Force "$ScriptDirectory\Modules\EventLogs.psm1"
Import-Module -Force "$ScriptDirectory\Modules\GeneralCollection.psm1"
Import-Module -Force "$ScriptDirectory\Modules\SCAP.psm1"


######################### Configuration Handling ###############################

function Import-Config {
    # .SYNOPSIS
    # Pull config object from file. Generates skeleton if necessary.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$File
    )
    $Version = [System.Version]"2.2.0"
    if (Test-Path -Path $File -PathType Leaf) {
        Try {
            $Config = $(Import-Clixml -ErrorAction Stop -Path $File)
        }
        Catch {
            throw "The file $File incorrectly formated, please delete to force recreation."
        }
    }
    elseif ( Test-Path -Path $File -PathType Container ) {
        throw "$File is a directory!"
    }
    else {
        $Config = [PSCustomObject]@{
            ConfigVersion       = $Version
            CreationTimeUTC     = Get-Date
            LastAccessTimeUTC   = Get-Date
            LastWriteTimeUTC    = Get-Date
            LastHDD             = ''
            BaseName            = Read-Host -Prompt "What is the base's name"
            ScanningOrg         = Read-Host -Prompt "What is the scanning organization (i.e. 52CS)"
            KnownDrives         = @{}
        }
    }
    if ($Config.ConfigVersion -ne $Version) { throw "Old config file, failing out."}
    Write-Host
    return $Config
}
function Update-Config {
    # .SYNOPSIS
    # Update config object, adding drive config if it doesn't exist.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$RootDirectory
    )

    function Read-SystemType {
        param (
            [Parameter(Mandatory=$True,Position=1)]
            [ValidateNotNullOrEmpty()]
            [String]$RootDirectory
        )

        ## Autopull if available
        if (Test-Path -Path "C:\Capre_rel.cer" -PathType Leaf) {
            return "CAPRE"
        }

        ## Request input if not
        Try {
            $PlatformList = Import-CSV -Path "$RootDirectory\PlatformList.csv"
        } Catch {
            throw "PlatformList.csv doesn't exist! Please reinstall SuperCAT."
        }

        $result = $(Read-Intent $PlatformList.SystemName "What type of system is this?")
        if ( $result -eq "Other") {
            return $(Read-Host -Prompt "What type of system is this")
        } else {
            return $result
        }
    }
    function Read-SystemVersion {
        ## Autopull if available

        ## Request input if not
        Write-Host "Please enter the version in the format MajorMinor"
        Write-Host "Example: 10 for major version 1 minor verion 0"
        while ($True) {
            $Result = Read-Host -Prompt "Version Number"
            if ($Result -notmatch "\d\d") {
                Write-Host "Please try again."
            }
            else {
                Write-Host
                return $Result
            }
        }
    }
    function Read-Classification {
        ## Autopull if available

        ## Request input if not
        $SelectionArray = @(
            "Unclassified",
            "Confidential",
            "Secret",
            "Top Secret",
            "Other"
        )
        $result = $(Read-Intent $SelectionArray "What is the classification?")
        if ( $result -eq "Other") {
            return $(Read-Host -Prompt "What is the classification")
        } else {
            return $result
        }
    }
    function Read-DriveName {
        ## Autopull if available

        ## Request input if not
        Write-Host "Please enter the assigned drive number, zero-paded"
        Write-Host "to three digits. Example: 007 for for drive seven"
        while ($True) {
            $Result = Read-Host -Prompt "Drive Number"
            if ($Result -notmatch "\d\d\d") {
                Write-Host "Please try again."
            }
            else {
                return $Result
            }
        }
    }

    $LocalDrive = (Get-WMIObject Win32_PhysicalMedia |
        Where-Object {$_.Tag -eq "\\.\PHYSICALDRIVE0"}).SerialNumber
    $Config.LastAccessTimeUTC = Get-Date
    if ($Config.KnownDrives.Keys -NotContains $LocalDrive) {
        if ($Config.KnownDrives.Count -gt 0) {
            Write-Host "Unknown drive. Would you like to add this `ndrive to database?"
            if ( !$(Read-Intent -TF) ) {
                Write-Host "Exiting! Nothing has been written."
                exit
            }
            else {
                Write-Host "Adding drive to database."
                Write-Host
            }
        }
        $Config.KnownDrives.$LocalDrive = @{
            CreationTimeUTC     = Get-Date
            LastAccessTimeUTC   = Get-Date
            LastWriteTimeUTC    = Get-Date
            DriveName           = Read-DriveName
            SystemType          = Read-SystemType $RootDirectory
            SystemVersion       = Read-SystemVersion
            Unit                = Read-Host -Prompt "What maintenance unit does this HDD belong to (i.e. 480AMXS)"
            Classification      = Read-Classification
        }
    }
    while ($True) {
        Write-Host "`n`n`n
            Base Name         = $($Config.BaseName)
            Organization      = $($Config.ScanningOrg)
            Drive Name        = $($Config.KnownDrives.$LocalDrive.DriveName)
            System Type       = $($Config.KnownDrives.$LocalDrive.SystemType)
            System Version    = $($Config.KnownDrives.$LocalDrive.SystemVersion)
            Maintenance Unit  = $($Config.KnownDrives.$LocalDrive.Unit)
            Classification    = $($Config.KnownDrives.$LocalDrive.Classification)"
        Write-Host "Is this information correct?"
        if ($(Read-Intent -TF)) { break }
        $Config.KnownDrives.$LocalDrive.LastWriteTimeUTC = Get-Date
        $Config.LastWriteTimeUTC = Get-Date
        $SelectionArray = @(
            "Base Name",
            "Organization",
            "Drive Name",
            "System Type",
            "System Version",
            "Maintenance Unit",
            "Classification"
        )
        switch($(Read-Intent $SelectionArray "What should be changed?")) {
            $SelectionArray[0] {$Config.BaseName                                = Read-Host -Prompt "Base Name"}
            $SelectionArray[1] {$Config.ScanningOrg                             = Read-Host -Prompt "Organization"}
            $SelectionArray[2] {$Config.KnownDrives.$LocalDrive.DriveName       = Read-DriveName}
            $SelectionArray[3] {$Config.KnownDrives.$LocalDrive.SystemType      = Read-SystemType $RootDirectory}
            $SelectionArray[4] {$Config.KnownDrives.$LocalDrive.SystemVersion   = Read-SystemVersion}
            $SelectionArray[5] {$Config.KnownDrives.$LocalDrive.Unit            = Read-Host -Prompt "Maintenance Unit"}
            $SelectionArray[6] {$Config.KnownDrives.$LocalDrive.Classification  = Read-Classification}
            Default {throw "Update-Config switch fell through."}
        }

    }
    $Config.KnownDrives.$LocalDrive.LastAccessTimeUTC = Get-Date
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
        [Switch]$PassThru
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
function Get-LogPrefix {
    # .SYNOPSIS
    # Pull system abbreviations and mesh config data to provide a log prefix.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$RootDirectory,

        [Parameter()]
        [Switch]$SCAP
    )
    Try {
        $PlatformList = Import-CSV -Path "$RootDirectory\PlatformList.csv"
    } Catch {
        throw "PlatformList.csv doesn't exist! Please reinstall SuperCAT."
    }

    $SystemAbbreviation = $(
        $PlatformList | Where-Object {
            $_.SystemName -eq $Config.KnownDrives.$($Config.LastHDD).SystemType
        }).SystemAbbreviation
    $Unit       = $Config.KnownDrives.$($Config.LastHDD).Unit
    $Date       = $(Get-Date -Format "yyyyMMdd_HHmm" -Date $Config.LastAccessTimeUTC)
    $Version    = $Config.KnownDrives.$($Config.LastHDD).SystemVersion
    $Drive      = $Config.KnownDrives.$($Config.LastHDD).DriveName
    if ($SCAP) {
        return "$Unit`_$SystemAbbreviation$Version`_$Drive"
    } else {
        return "$Date`_$Unit`_$SystemAbbreviation$Version`_$Drive"
    }
}

################################ General #######################################

## Check for administrative privildges, warn if necessary, continue
if(([Security.Principal.WindowsPrincipal](
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator) -eq $False){

    Write-Warning "THIS SCRIPT WAS NOT RUN AS AN ADMINISTRATOR! SOME TASKS MAY NOT WORK OR PROVIDE INACCURATE RESULTS!"
}

## Fix time on the laptop, and set it to UTC
Set-Time | Out-Null

$Config = Import-Config "$ScriptDirectory\config.xml" |
    Update-Config -RootDirectory $ScriptDirectory |
    Export-Config "$ScriptDirectory\config.xml" -PassThru
$LogPrefix = Get-LogPrefix $Config $ScriptDirectory
$AllOptions = @(
    "Update Antivirus (Requires Pre-Approved Actions)",
    "Collect Computer Information",
    "Initialize Antivirus Scan",
    "Collect Antivirus Logs",
    "Initialize SCAP",
    "Collect Windows Event Logs",
    "All Tasks (No Antivirus Updating, Auto exits)",
    "Exit Program"
)

$ExitLock = @() ## Keep track of what programs have been started.
[List[string]]$RemainingOptions = $AllOptions
while ($Chosen -notcontains $AllOptions[-1]) {
    $Chosen = Read-Intent $RemainingOptions -Multiple
    ## Mark all selected options as complete in the list, preventing their execution.
    foreach ($Selected in $Chosen.Where({($_ -ne $AllOptions[-1]) -and
        !($_.Contains("(Complete)")) -and !($_.Contains("(Unavailable)"))})) {
        $Index = $RemainingOptions.IndexOf($Selected)
        $RemainingOptions[$Index] = $RemainingOptions[$Index].Insert(0,"(Complete) ")

        if (($RemainingOptions[-2] -eq $AllOptions[-2]) -and
            ($AllOptions[1..$($AllOptions.GetUpperBound(0)-2)] -contains $Selected)) {
            $RemainingOptions[-2] = $RemainingOptions[-2].Insert(0,"(Unavailable) ")
        }

    }

    ## Handles "All Tasks" by setting $Chosen to everything but AV.
    ## Unless of course the user selects AV as well.
    if ($Chosen -contains $AllOptions[-2]) {
        if ($Chosen -contains $AllOptions[0]) { ## AV
            $Chosen = $AllOptions[0..$($AllOptions.GetUpperBound(0)-2)]
        }
        else { ## No AV
            $Chosen = $AllOptions[1..$($AllOptions.GetUpperBound(0)-2)]
        }
        $Chosen += $AllOptions[-1]
    }

    switch($Chosen) {
        $AllOptions[0]  { Update-AVSignatures $ScriptDirectory }
        $AllOptions[1]  { Import-Identifiers $Config "$ScriptDirectory\..\..\Outputs\GatheredLogs\$LogPrefix" }
        $AllOptions[2]  { $ExitLock += Start-Antivirus $ScriptDirectory "$ScriptDirectory\..\..\Outputs\AVLogs\$LogPrefix" }
        $AllOptions[3]  { Import-AntivirusLogs "$ScriptDirectory\..\..\Outputs\AVLogs" }
        $AllOptions[4]  { $ExitLock += Start-SCAP $ScriptDirectory "$ScriptDirectory\..\..\Outputs\SCAPLogs\$(Get-LogPrefix $Config $ScriptDirectory -SCAP)" }
        $AllOptions[5]  { Import-EventLogs "$ScriptDirectory\..\..\Outputs\EventLogs\$LogPrefix"}
        $AllOptions[-2] { throw "`$AllOptions[-2] if statement failed to evaluate correctly." }
        $AllOptions[-1] { Out-Null }
        {$_.Contains("(Complete) ")} {
            Write-Host "Skipping $($_.Remove(0, 11)); already run"
        }
        {$_.Contains("(Unavailable) ")} {
            Write-Host "Skipping $($_.Remove(0, 14)); some elements already run."
        }
        Default {
            Write-Host "Please only input numbers 0 to $($AllOptions.GetUpperBound(0)) and commas (i.e. 1,3,5)"
            Write-Host "Recieved Input $_"
        }
    }
    Write-Host
}

## Prevent exiting if ExitLock still has an active process
if (($ExitLock.Count -ne 0) -and ($ExitLock.HasExited -contains $False)) {
    Write-Host "The following processes are still running: $($ExitLock.Where(
        {$_.HasExited -eq $False}).ProcessName)"
    Write-Host "Waiting for processes to finish up..."
    $ExitLock.WaitForExit()
    Write-Host "Done!"
}
