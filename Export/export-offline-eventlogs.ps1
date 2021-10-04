$Drive = Read-Host "Type in the exact path the .evtx event files are located"

$EventLogs = (Get-ChildItem -Path "$Drive" | Where-Object {$_.Extension -eq ".evtx"}).fullname

foreach($EventLog in $EventLogs){
    $Type = (Get-ChildItem $EventLog).BaseName
    Write-Output "Writing $Type to CSV... This may take some time..."
    Get-WinEvent -Path $EventLog | Sort-Object -Property TimeCreated -Descending | Export-CSV -NoTypeInformation -Path "$Drive\EXPORTED-$Type-EVTX.csv"
}

Write-Output "Job's done!"