function Import-EventLog {
    # .SYNOPSIS
    # Gathers Windows Events logs and sends it to the location of the script
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$LogPrefix
    )

    if (!$(Test-Path $($LogPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($LogPrefix | Split-Path) | Out-Null }
    Write-Host "Exporting Windows event logs to .evtx..."

    wevtutil.exe epl System "$LogPrefix`_System.evtx"
    wevtutil.exe epl Security "$LogPrefix`_Security.evtx"
    wevtutil.exe epl Application "$LogPrefix`_Application.evtx"
}
Export-ModuleMember -Function Import-EventLog
