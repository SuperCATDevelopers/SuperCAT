<###############################################################################
## SUPERCAT (CYBER ASSESSMENT TOOL) V0.3.4
## DEVELOPED BY: SSGT CLINTON REEL // CLINTON.REEL@US.AF.MIL
## ADDITIONAL DEVELOPERS IN CONTRIBUTORS.TXT
###############################################################################>

#########################  Parameters  #########################################
[CmdletBinding(DefaultParameterSetName="Interactive")]
param (
    [Alias("h","?")]
    [Parameter(ParameterSetName="Cmdline")]
    [Parameter(ParameterSetName="Interactive")]
    [Switch]$Help,

    [Parameter(ParameterSetName="Cmdline")]
    [Parameter(ParameterSetName="Interactive")]
    [Switch]$List,

    [Parameter(Mandatory=$True,Position=0,ParameterSetName="Cmdline")]
    [String]$Options,

    [Parameter(ParameterSetName="Interactive",
    HelpMessage="Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS (i.e. 2020-01-01T13:39:00)")]
    [Parameter(Mandatory=$True,Position=1,ParameterSetName="Cmdline",
    HelpMessage="Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS (i.e. 2020-01-01T13:39:00)")]
    [String]$Time
)

##################### Early Variable Requirements ##############################

$ScriptVersion = [System.Version]"0.3.4"

$ScriptDirectory = $MyInvocation.MyCommand.Path | Split-Path

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
$AdminRequired = @(
    "Update Antivirus (Requires Pre-Approved Actions)",
    "Initialize Antivirus Scan",
    "Initialize SCAP",
    "All Tasks (No Antivirus Updating, Auto exits)"
)

$RemainingOptions = @()
$RemainingOptions += $AllOptions

############################# Module Import ####################################
try {
    Import-Module -Force -ErrorAction Stop "$ScriptDirectory\Modules\Support.psm1"
} catch {
    throw "Missing Support.psm1!"
}

try {Import-Module -Force -ErrorAction Stop "$ScriptDirectory\Modules\Antivirus.psm1"}
catch {
    Write-Warning "Missing Antivirus.psm1, unable to run, update, or import logs from antivirus."
    $RemainingOptions[0] = $RemainingOptions[0].Insert(0,"(Unavailable) ")
    $RemainingOptions[2] = $RemainingOptions[2].Insert(0,"(Unavailable) ")
    $RemainingOptions[3] = $RemainingOptions[3].Insert(0,"(Unavailable) ")
}
try {Import-Module -Force -ErrorAction Stop "$ScriptDirectory\Modules\EventLogs.psm1"}
catch {
    Write-Warning "Missing EventLogs.psm1, unable to import event logs."
    $RemainingOptions[5] = $RemainingOptions[5].Insert(0,"(Unavailable) ")
}
try {Import-Module -Force -ErrorAction Stop "$ScriptDirectory\Modules\GeneralCollection.psm1"}
catch {
    Write-Warning "Missing GeneralCollection.psm1, unable to collect general information."
    $RemainingOptions[1] = $RemainingOptions[1].Insert(0,"(Unavailable) ")
}
try {Import-Module -Force -ErrorAction Stop "$ScriptDirectory\Modules\SCAP.psm1"}
catch {
    Write-Warning "Missing SCAP.psm1, unable to run SCAP."
    $RemainingOptions[4] = $RemainingOptions[4].Insert(0,"(Unavailable) ")
}

## Mark "All Tasks" unavailable if any of the functions are unavailable.
if ($RemainingOptions[1..$($RemainingOptions.GetUpperBound(0)-2)] -contains "(Unavailable) ") {
    $RemainingOptions[-2] = $RemainingOptions[-2].Insert(0,"(Unavailable) ")
}

##################### Parameter Processing #####################################

if ($Help) {
    Write-Host
    Write-Host "SuperCAT version $($($ScriptVersion).ToString())"
    Write-Host
    Write-Host "System Requirements:"
    Write-Host "Windows 7 or greater with Powershell 2 or greater."
    Write-Host
    Write-Host "Parameters:"
    Write-Host "  -Help     Display this message."
    Write-Host "  -List     Display only execution options"
    Write-Host "  -Options  Select one or more execution options. Please"
    Write-Host "            only input numbers and commas (i.e. 1,25,6)."
    Write-Host "            Requires -Time"
    Write-Host "  -Time     Set the system time in UTC. To skip, write"
    Write-Host "            `"trust`". Please enter the date in the format"
    Write-Host "            YYYY-MM-DDTHH:MM:SS (i.e. 2020-01-31T13:39:00)"
    Write-Host
    Write-Host "Execution Options:"
    for ($i=0; $i -lt $AllOptions.Count; $i++) {
        Write-Host $i "=" $AllOptions[$i]
    }
    Write-Host
    exit
}
if ($List) {
    Write-Host
    Write-Host "The following are your options, please"
    Write-Host "input only numbers and commas (i.e. 1,25,6):"
    for ($i=0; $i -lt $AllOptions.Count; $i++) {
        Write-Host $i "=" $AllOptions[$i]
    }
    Write-Host
    exit
}
if ( $Options ) {
    $ResultList = $Options.Split(",")
    if ($Options -notmatch "^\d+(,\d+)*$") {
        throw "Please only input numbers and commas (i.e. 1,25,6)"
    }
    elseif (( [int[]]$ResultList -ge $AllOptions.Count ) -or ( $ResultList -lt 0 )) {
        throw "Please ensure your entry is between 0 and $($AllOptions.Count - 1)"
    }
    elseif ($(Get-Duplicate $ResultList)) {
        throw "Please ensure there are no duplicates in your entry."
    }
    else {
        $Chosen = $AllOptions[$ResultList]
    }
    $NoInteractive=$True
} else { $NoInteractive=$False }

if (Test-Path -Path "$ScriptDirectory\SuperCAT.lck") {
    Write-Host "SuperCAT already running. If you believe this is an error,"
    Write-Host "delete SuperCAT.lck"
    exit
} else {
    New-Item -ItemType file "$ScriptDirectory\SuperCAT.lck" | Out-Null
}


######################### Configuration Handling ###############################

function Import-Config {
    # .SYNOPSIS
    # Pull config object from file. Generates skeleton if necessary.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$File,

        [Parameter()]
        [Bool]$NoInteractive
    )
    $ConfigVersion = [System.Version]"0.2.3"
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
    elseif ( $NoInteractive ) {
        throw "Please run interactively to generate config.xml first."
    }
    else {
        $Config = [PSCustomObject]@{
            ConfigVersion       = $ConfigVersion
            CreationTimeUTC     = Get-Date
            LastAccessTimeUTC   = Get-Date
            LastWriteTimeUTC    = Get-Date
            LastHDD             = ''
            Location            = Read-Host -Prompt "Which location is this"
            ScanningOrg         = Read-Host -Prompt "What is the scanning organization"
            KnownDrives         = @{}
        }
    }
    if ($Config.ConfigVersion -ne $ConfigVersion) { throw "Old config file, failing out."}
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
        [String]$RootDirectory,

        [Parameter()]
        [Bool]$NoInteractive
    )
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
        if ($NoInteractive) {
            throw "Please run interactively first to generate config.xml"
        }
        if ($Config.KnownDrives.Count -gt 0) {
            Write-Host "================================================"
            Write-Host "Unknown drive. Would you like to add this `ndrive to database?"
            Write-Host "================================================"
            if ( !$(Read-Intent -TF) ) {
                Write-Host "Exiting! Nothing has been written."
                if (Test-Path -Path "$ScriptDirectory\SuperCAT.lck") {
                    Remove-Item -Path "$ScriptDirectory\SuperCAT.lck"
                }
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
            SystemOwner         = Read-Host -Prompt "What organization does this system belong to"
            Classification      = Read-CSV "$RootDirectory\ClassificationList.csv" "Classification"
        }
    }
    while ($True) {
        Write-Host
        Write-Host "================================================"
        if (!$NoInteractive) {
            Write-Host "Is this information correct?"
            Write-Host
        }
        Write-Host "Location            = $($Config.Location)"
        Write-Host "Organization        = $($Config.ScanningOrg)"
        Write-Host "Drive Name          = $($Config.KnownDrives.$LocalDrive.DriveName)"
        Write-Host "System Type         = $($Config.KnownDrives.$LocalDrive.SystemType)"
        Write-Host "System Owner        = $($Config.KnownDrives.$LocalDrive.SystemOwner)"
        Write-Host "Classification      = $($Config.KnownDrives.$LocalDrive.Classification)"
        Write-Host "================================================"
        if ($NoInteractive -or $(Read-Intent -TF)) { Write-Host; break }
        $Config.KnownDrives.$LocalDrive.LastWriteTimeUTC = Get-Date
        $Config.LastWriteTimeUTC = Get-Date
        $SelectionArray = @(
            "Location",
            "Organization",
            "Drive Name",
            "System Type",
            "System Owner",
            "Classification"
        )
        switch($(Read-Intent $SelectionArray "What should be changed?")) {
            $SelectionArray[0] {$Config.Location                                = Read-Host -Prompt "Location"}
            $SelectionArray[1] {$Config.ScanningOrg                             = Read-Host -Prompt "Organization"}
            $SelectionArray[2] {$Config.KnownDrives.$LocalDrive.DriveName       = Read-DriveName}
            $SelectionArray[3] {$Config.KnownDrives.$LocalDrive.SystemType      = Read-CSV "$RootDirectory\SystemList.csv" "SystemName"}
            $SelectionArray[4] {$Config.KnownDrives.$LocalDrive.SystemOwner     = Read-Host -Prompt "System Owner"}
            $SelectionArray[5] {$Config.KnownDrives.$LocalDrive.Classification  = Read-CSV "$RootDirectory\ClassificationList.csv" "Classification"}
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
    Write-Warning "THIS SCRIPT WAS NOT RUN AS AN ADMINISTRATOR!"
    Write-Warning "SOME TASKS ARE UNAVAILABLE OR MAY PROVIDE INCOMPLETE RESULTS!"
    foreach ($Item in $AdminRequired) {
        $Index = $RemainingOptions.IndexOf($Item)
        if ($RemainingOptions[$Index] -notcontains "(Unavailable) ") {
            $RemainingOptions[$Index] = $RemainingOptions[$Index].Insert(0,"(Unavailable) ")
        }
    }
}
$LogPath = "$ScriptDirectory..\..\Outputs"
## Fix time on the laptop, and set it to UTC
Set-Time $Time | Out-Null

$Config = Import-Config "$ScriptDirectory\config.xml" -NoInteractive $NoInteractive |
    Update-Config -RootDirectory $ScriptDirectory -NoInteractive $NoInteractive |
    Export-Config "$ScriptDirectory\config.xml" -PassThru
$LogPrefix = Get-LogPrefix $Config $ScriptDirectory
$ExitLock = @() ## Keep track of what programs have been started.
while (($Chosen -notcontains $AllOptions[-1]) -or ($Options)) {
    if (!($Options)) {
        $Chosen = Read-Intent $RemainingOptions
    }
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
            Write-Host "Skipping $($_.Remove(0, 14)); some elements run, module not imported, or running as user."
        }
        Default {
            Write-Host "Please only input numbers 0 to $($AllOptions.GetUpperBound(0)) and commas (i.e. 1,3,5)"
            Write-Host "Recieved Input $_"
        }
    }
    ## Mark all selected options as complete in the list, preventing their execution.
    foreach ($Selected in $Chosen.Where({($_ -ne $AllOptions[-1]) -and
        ($_ -notcontains "(Complete)") -and ($_ -notcontains "(Unavailable)")})) {
        $Index = $RemainingOptions.IndexOf($Selected)
        $RemainingOptions[$Index] = $RemainingOptions[$Index].Insert(0,"(Complete) ")

        if (($RemainingOptions[-2] -eq $AllOptions[-2]) -and
            ($AllOptions[1..$($AllOptions.GetUpperBound(0)-2)] -contains $Selected)) {
            $RemainingOptions[-2] = $RemainingOptions[-2].Insert(0,"(Unavailable) ")
        }
    }
    Write-Host
    if ( $Options ) { break }
}

## Prevent exiting if ExitLock still has an active process
if (($ExitLock.Count -ne 0) -and ($ExitLock.HasExited -contains $False)) {
    Write-Host "The following processes are still running: $($ExitLock.Where(
        {$_.HasExited -eq $False}).ProcessName)"
    Write-Host "Waiting for processes to finish up..."
    $ExitLock.WaitForExit()
    Write-Host "Done!"
}

if (Test-Path -Path "$ScriptDirectory\SuperCAT.lck") {
    Remove-Item -Path "$ScriptDirectory\SuperCAT.lck"
}
