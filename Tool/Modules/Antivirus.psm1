function Update-AVSignatures {
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
Export-ModuleMember -Function Update-AVSignatures

function Import-AntivirusLogs {
    # .SYNOPSIS
    # Sends any available antivirus logs to the location of the script.

    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$Directory
    )

    if (!$(Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null}
    Write-Host "Gathering scan logs..."
    if($Win32Caption -like "*Windows 7*"){
        Copy-Item -Path "C:\ProgramData\McAfee\DestkopProtection\OnDemandScanLog.txt" -Destination "$Directory"
    }
    else{
        Copy-Item -Path "C:\ProgramData\McAfee\Endpoint Security\Logs\" -Destination "$Directory" -Recurse
    }
}
Export-ModuleMember -Function Import-AntivirusLogs

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
        Start-Process -FilePath "$RootDirectory\Scripts\McAfeeAV_v2\w64\scan.exe" -ArgumentList "/DRIVER=$RootDirectory\Scripts\McAfeeAV_v2\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$LogPrefix`_AV`_Report.txt /HTML $LogPrefix`_AV_REPORT.html"
    }
    else{
        Start-Process -FilePath "$RootDirectory\Scripts\McAfeeAV_v2\w32\scan.exe" -ArgumentList "/DRIVER=$RootDirectory\Scripts\McAfeeAV_v2\DAT /ANALYZE /ADL /SECURE /NOBREAK /TIMEOUT=10 /THREADS=64 /REPORT=$LogPrefix`_AV`_Report.txt /HTML $LogPrefix`_AV_REPORT.html"
    }
}
Export-ModuleMember -Function Start-Antivirus
