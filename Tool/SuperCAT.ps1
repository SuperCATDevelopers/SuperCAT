<###############################################################################
## SUPERCAT (CYBER ASSESSMENT TOOL) V0.3.4
## DEVELOPED BY: SSGT CLINTON REEL // CLINTON.REEL@US.AF.MIL
## ADDITIONAL DEVELOPERS IN CONTRIBUTORS.TXT
###############################################################################>

######################### Module Imports #######################################

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
    $Version = [System.Version]"0.2.2"
    if (Test-Path -Path $File -PathType Leaf) {
        Try {
            $Config = $(Import-Clixml -ErrorAction Stop -Path $File)
        }
        Catch {
            throw "The file $File incorrectly formated, please delete to force recreation."
        }
    }
    else {
        $Config = [PSCustomObject]@{
            ConfigVersion       = $Version
            CreationTimeUTC     = Get-Date
            LastAccessTimeUTC   = Get-Date
            LastWriteTimeUTC    = Get-Date
            LastHDD             = ''
            Location            = Read-Host -Prompt "Which location is this"
            ScanningOrg         = Read-Host -Prompt "What is the scanning organization"
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
    function Read-SystemVersion {
        # .SYNOPSIS
        # Request the version number from the user, validating the format.
        Write-Host "================================================"
        Write-Host "Please enter the version in the format MajorMinor"
        Write-Host "Example: 10 for major version 1 minor verion 0"
        Write-Host "================================================"
        while ($True) {
            try {
                [int]$Result = Read-Host -Prompt "Version Number"
            } catch {
                Write-Host "Please enter a number."
            }
            if ($Result -gt 99) {
                Write-Host "Please enter a version less than 99."
            }
            else {
                return $([String]$Result).PadRight(2,"0")
            }
        }
    }
    function Read-DriveName {
        # .SYNOPSIS
        # Ask the user for the drive number, padding to 3 digits.
        Write-Host "================================================"
        Write-Host "Please enter the assigned drive number, between"
        Write-Host "0 and 999. Example: 27"
        Write-Host "================================================"
        while ($True) {
            try {
                [int]$Result = Read-Host -Prompt "Drive Number"
            } catch {
                Write-Host "Please enter a number."
            }
            if ($Result -gt 999) {
                Write-Host "Please enter a number less than 999."
            }
            else {
                return $([String]$Result).PadLeft(3,"0")
            }
        }
    }

    $LocalDrive = $(Get-WmiObject Win32_PhysicalMedia |
        Where-Object {$_.Dependent -eq $(
        Get-WmiObject Win32_DiskDriveToDiskPartition |
        Where-Object {$_.Dependent -eq $(
        Get-WmiObject Win32_LogicalDiskToPartition |
        Where-Object {$_.Dependent -Like $Env:SystemDrive})})}).SerialNumber
    $Config.LastAccessTimeUTC = Get-Date
    if ($Config.KnownDrives.Keys -NotContains $LocalDrive) {
        if ($Config.KnownDrives.Count -gt 0) {
            Write-Host "================================================"
            Write-Host "Unknown drive. Would you like to add this `ndrive to database?"
            Write-Host "================================================"
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
            SystemType          = Read-CSV "$RootDirectory\SystemList.csv" "SystemName"
            SystemVersion       = Read-SystemVersion
            SystemOwner         = Read-Host -Prompt "What organization does this system belong to"
            Classification      = Read-CSV "$RootDirectory\ClassificationList.csv" "Classification"
        }
    }
    while ($True) {
        Write-Host
        Write-Host "================================================"
        Write-Host "Is this information correct?"
        Write-Host
        Write-Host "Location            = $($Config.Location)"
        Write-Host "Organization        = $($Config.ScanningOrg)"
        Write-Host "Drive Name          = $($Config.KnownDrives.$LocalDrive.DriveName)"
        Write-Host "System Type         = $($Config.KnownDrives.$LocalDrive.SystemType)"
        Write-Host "System Version      = $($Config.KnownDrives.$LocalDrive.SystemVersion)"
        Write-Host "System Owner        = $($Config.KnownDrives.$LocalDrive.SystemOwner)"
        Write-Host "Classification      = $($Config.KnownDrives.$LocalDrive.Classification)"
        Write-Host "================================================"
        if ($(Read-Intent -TF)) { Write-Host; break }
        $Config.KnownDrives.$LocalDrive.LastWriteTimeUTC = Get-Date
        $Config.LastWriteTimeUTC = Get-Date
        $SelectionArray = @(
            "Location",
            "Organization",
            "Drive Name",
            "System Type",
            "System Version",
            "System Owner",
            "Classification"
        )
        switch($(Read-Intent $SelectionArray "What should be changed?")) {
            $SelectionArray[0] {$Config.Location                                = Read-Host -Prompt "Location"}
            $SelectionArray[1] {$Config.ScanningOrg                             = Read-Host -Prompt "Organization"}
            $SelectionArray[2] {$Config.KnownDrives.$LocalDrive.DriveName       = Read-DriveName}
            $SelectionArray[3] {$Config.KnownDrives.$LocalDrive.SystemType      = Read-CSV "$RootDirectory\SystemList.csv" "SystemName"}
            $SelectionArray[4] {$Config.KnownDrives.$LocalDrive.SystemVersion   = Read-SystemVersion}
            $SelectionArray[5] {$Config.KnownDrives.$LocalDrive.SystemOwner     = Read-Host -Prompt "System Owner"}
            $SelectionArray[6] {$Config.KnownDrives.$LocalDrive.Classification  = Read-CSV "$RootDirectory\ClassificationList.csv" "Classification"}
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
    $ClassAbbreviation = Read-CSV `
        -Path   "$RootDirectory\ClassificationList.csv" `
        -Column "Classification" `
        -Select "ClassificationAbbreviation" `
        -Config $Config
    $SystemAbbreviation =Read-CSV `
        -Path   "$RootDirectory\SystemList.csv" `
        -Column "SystemName" `
        -Select "SystemAbbreviation" `
        -Config $Config
    $SystemOwner  = $Config.KnownDrives.$($Config.LastHDD).SystemOwner
    $Date         = $(Get-Date -Format "yyyyMMdd_HHmm" -Date $Config.LastAccessTimeUTC)
    $Version      = $Config.KnownDrives.$($Config.LastHDD).SystemVersion #TODO: Remove Version from config
    $Drive        = $Config.KnownDrives.$($Config.LastHDD).DriveName
    if ($SCAP) {
        return "$ClassAbbreviation`_$SystemOwner`_$SystemAbbreviation`_$Drive`_$($Config.LastHDD)"
    } else {
        return "$ClassAbbreviation`_$Date`_$SystemOwner`_$SystemAbbreviation`_$Drive`_$($Config.LastHDD)"
    }
}

################################ General #######################################

## Check for administrative privildges, warn if necessary, continue
if(([Security.Principal.WindowsPrincipal](
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator) -eq $False){

    Write-Warning "THIS SCRIPT WAS NOT RUN AS AN ADMINISTRATOR! SOME TASKS MAY NOT WORK OR PROVIDE INACCURATE RESULTS!"
}
$LogPath = "$ScriptDirectory..\..\Outputs"
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
$RemainingOptions = @()
$RemainingOptions += $AllOptions
while ($Chosen -notcontains $AllOptions[-1]) {
    $Chosen = Read-Intent $RemainingOptions -Multiple
    ## Handles "All Tasks" by setting $Chosen to everything but AV Update.
    ## Unless of course the user selects AV Update as well.
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
        $AllOptions[0]  { Update-AVSignature $ScriptDirectory }
        $AllOptions[1]  { Import-Identifier $Config "$LogPath\GatheredLogs\$LogPrefix" }
        $AllOptions[2]  { $ExitLock += Start-Antivirus $ScriptDirectory "$LogPath\McAfeeLogs\$LogPrefix" }
        $AllOptions[3]  { Import-AntivirusLog "$LogPath\McAfeeLogs\$LogPrefix" "$LogPath\EventLogs\$LogPrefix" }
        $AllOptions[4]  { $ExitLock += Start-SCAP $ScriptDirectory "$LogPath\SCAPLogs\$(Get-LogPrefix $Config $ScriptDirectory -SCAP)" }
        $AllOptions[5]  { Import-EventLog "$LogPath\EventLogs\$LogPrefix"}
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
