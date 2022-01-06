function Import-Identifiers {
    # .SYNOPSIS
    # Export general system Information
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$LogPrefix
    )

    if (!$(Test-Path $($LogPrefix | Split-Path))) { New-Item -ItemType Directory -Path $($LogPrefix | Split-Path) | Out-Null }
    $Win32OS            = Get-WMIObject -Class Win32_OperatingSystem
    $BaseName           = $Config.BaseName
    $LogPath            = "$LogPrefix`_Info.txt"
    $OSName             = $Win32OS.Caption
    $OSVer              = $Win32OS.Version
    $PSVersion          = Get-Host | Select-Object Version
    $ChasisSerialNumber = (Get-WMIObject -Class Win32_BIOS).SerialNumber ## TODO: Find a unique ID for the chasis
    $MACAddress         = (Get-WMIObject -Class Win32_NetworkAdapter |
      Where-Object {$Null -ne $_.MACaddress} |
      Select-Object -First 1).MACAddress

    ## Adds the generic information about the machine to a file.
    Write-Output "Writing computer name, serial number, and base info..."
    Add-Content -Value "Date: $(Get-Date)" -Path $LogPath
    Add-Content -Value "PowerShell Version: $PSVersion" -Path "$GatherLogs\$ComputerName`_Info.txt"
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
          Export-CSV -Path "$LogPrefix`_HardDrives.csv" -NoTypeInformation
    }

    # Systeminfo has a lot of additional information that will be written to a file.
    Write-Host "Writing Systeminfo..."
    systeminfo > "$LogPrefix`_SystemInfo.txt"

    # This is a list of all of the relevant registry keys that have information about the installation of programs.
    # After it gathers these items, it queries them for application information and sends it to a .CSV.
    Write-Host "Gathering Installed Programs..."
    $AppsRegistryLocations = (
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
    )
    if($(Get-WMIObject -Class Win32_OperatingSystem).OSArchitecture -eq "64-bit"){
        $AppsRegistryLocations += "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
    }

    ##TODO: Why does this not work on Win7
    $Apps = Get-ChildItem $AppsRegistryLocations | Get-ItemProperty |
      Sort-Object DisplayName |
      Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation,
        InstallDate,DisplayIcon,URLInfoAbout,EstimatedSize

    Write-Host "Found $($Apps.count) applications. Writing to CSV..."
    $Apps | Export-CSV -NoTypeInformation -Path "$LogPrefix`_Programs.csv"

    # Gathers information on the local users
    # Are they active? Are they disabled? Are they locked?
    # What accounts are available?
    Write-Host "Writing local users..."
    Get-LocalUser | Select-Object Name,Enabled,PasswordRequired,PasswordExpires,
        LastLogon,SID | Export-CSV -NoTypeInformation -Path "$LogPrefix`_Accounts.csv"

    # Gathers the open ports and active connections currently on the machine and writes to a .CSV.
    Write-Host "Writing open ports..."
    Get-NetTCPConnection |
        Export-CSV -NoTypeInformation -Path "$LogPrefix`_Ports.csv"

    # Gathers the current services and sends it to a CSV.
    Write-Host "Writing current processes..."
    Get-Service | Select-Object Name,ServiceName,DisplayName,Status |
        Export-CSV -NoTypeInformation -Path "$LogPrefix`_Services.csv"
}
Export-ModuleMember -Function Import-Identifiers
