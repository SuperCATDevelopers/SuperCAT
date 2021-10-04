$Drive = Read-Host "Type in the exact path the .hiv registry files are located"

$Regs = (Get-ChildItem -Path "$Drive" | Where-Object {$_.Extension -eq ".hiv"}).fullname

foreach($Reg in $Regs){
    Write-Output "Loading $Reg..."
    reg load "HKLM\TempHive" $Reg | Out-Null
    
    $Apps = Get-ChildItem "HKLM:\TempHive" | Get-ItemProperty | Where-Object {$_.DisplayName -ne $null} | Sort-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation,InstallDate,DisplayIcon,URLInfoAbout,EstimatedSize
    Write-Output "Found $($Apps.count) applications to write to CSV..."
    $Apps | Export-CSV -NoTypeInformation -Path "$Drive\EXPORTED-Programs.csv" -Append

    [gc]::collect()
    Start-Sleep -Seconds 2
    reg unload "HKLM\TempHive" | Out-Null
}

Get-ChildItem "$Drive" | Where-Object {$_.Extension -eq ".hiv" -and $_.FullName -notin $Regs} | Remove-Item -Force
Write-Output "Job's Done!"