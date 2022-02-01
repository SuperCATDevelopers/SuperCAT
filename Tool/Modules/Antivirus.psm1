function Update-AVSignature {
    # .SYNOPSIS
    # Update antivirus definitions.
    # .DESCRIPTION
    # Updates the antivirus definitions on the system to what is available
    # on the disc, but only if the definitions are older. Note: This option is
    # separated from the other tasks, for teams only looking to collect data.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$RootDirectory
    )

    ##TODO: Handle multiple signatures and validate file type.
    Write-Host "Checking DAT Signatures..."
    $InstalledDAT = (Get-Childitem "C:\Program Files (x86)\Common Files\McAfee\Engine\avvscan.dat").CreationTime
    $CATDAT       = (Get-Childitem "$RootDirectory\Scripts\McAfeeAV_v2\DAT\CM*").CreationTime
    $CATDATName   = (Get-Childitem "$RootDirectory\Scripts\McAfeeAV_v2\DAT\CM*").Name

    if($InstalledDAT -lt $CATDAT){
        Write-Host "Installing new DAT Signatures..."
        Start-Process -FilePath "$RootDirectory\Scripts\McAfeeAV_v2\DAT\$CATDATName" `
          -ArgumentList "/SILENT /F"
    }
    else{
        Write-Host "Installed DAT files are more up-to-date than what is on the disc."
    }
}
Export-ModuleMember -Function Update-AVSignature

function Import-AntivirusLog {
    # .SYNOPSIS
    # Sends any available antivirus logs to the location of the script.

    param (
        [Parameter(Mandatory=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$McAfeePrefix,

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$EventLogsPrefix
    )

    if (!$(Test-Path $($McAfeePrefix | Split-Path))) { New-Item -ItemType Directory -Path $($McAfeePrefix | Split-Path) | Out-Null }
    if (!$(Test-Path $($EventLogsPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($EventLogsPrefix | Split-Path) | Out-Null }
    Write-Host "Gathering scan logs..."
    if (Test-Path -PathType Leaf -Path "C:\ProgramData\McAfee\DestkopProtection\OnDemandScanLog.txt"){
        Copy-Item -Path "C:\ProgramData\McAfee\DestkopProtection\OnDemandScanLog.txt" -Destination "$McAfeePrefix`_OnDemandScanLog.txt"
    }
    if (Test-Path -PathType Leaf -Path "C:\ProgramData\McAfee\Endpoint Security\Logs\*"){
        Copy-Item -Path "C:\ProgramData\McAfee\Endpoint Security\Logs\" -Destination "$McAfeePrefix`_EndpointSecurity\" -Recurse
    }
    if ($(wevtutil.exe el).Contains("Microsoft-Windows-Windows Defender/Operational")){
        wevtutil.exe epl "Microsoft-Windows-Windows Defender/Operational" "$EventLogsPrefix`_WindowsDefender.evtx"
    }
}
Export-ModuleMember -Function Import-AntivirusLog

function Start-Antivirus {
    # .SYNOPSIS
    #  Runs an antivirus scan on the machine, sending any available antivirus logs
    #  to the location of the script.
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$RootDirectory,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$LogPrefix
    )

    if (!$(Test-Path $($LogPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($LogPrefix | Split-Path) | Out-Null }
    Write-Host "Running antivirus scan..."
    if($(Get-WMIObject -Class Win32_OperatingSystem).OSArchitecture -eq "64-bit"){
        return Start-Process -PassThru -FilePath "$RootDirectory\Scripts\McAfeeAV_v2\w64\scan.exe" -ArgumentList "/DRIVER=$RootDirectory\Scripts\McAfeeAV_v2\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$LogPrefix`_AV`_Report.txt /HTML $LogPrefix`_AV_REPORT.html"
    }
    else{
        return Start-Process -PassThru -FilePath "$RootDirectory\Scripts\McAfeeAV_v2\w32\scan.exe" -ArgumentList "/DRIVER=$RootDirectory\Scripts\McAfeeAV_v2\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$LogPrefix`_AV`_Report.txt /HTML $LogPrefix`_AV_REPORT.html"
    }
}
Export-ModuleMember -Function Start-Antivirus
