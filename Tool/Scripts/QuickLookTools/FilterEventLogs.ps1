$Drive = Read-Host "Type in the exact path the .evtx event files are located"
$EventLogs = (Get-ChildItem -Path "$Drive" | Where-Object {$_.Extension -eq ".evtx"}).fullname

$EventIDsFile = Read-Host "Type in the exact path the whitespace-delimited text file of event IDs"
$EventIDs = (Get-Content $EventIDsFile).Trim().Split()

foreach($EventLog in $EventLogs){
    $Type = (Get-ChildItem $EventLog).BaseName
    Write-Output "Writing $Type to CSV... This may take some time..."
    Get-WinEvent -Path $EventLog | Sort-Object -Property TimeCreated -Descending | Export-CSV -NoTypeInformation -Path "$Drive\EXPORTED-$Type-EVTX.csv"
	$CSV = Import-Csv "$Drive\EXPORTED-$Type-EVTX.csv"
	$row = 0
	foreach ($line in $CSV){
		$row++
		if($EventIDs -contains $line.Id){
			Write-Output (-join("EventID ", $line.Id, " found in EXPORTED-$Type-EVTX.csv on line $row"))
			Write-Output $line | Export-Csv -Path "$Drive\FLAGGED-EVENTS.csv" -Append -NoTypeInformation
		}
	}
}

Write-Output "Flagged Events written to $Drive\FLAGGED-EVENTS.csv"
Write-Output "Job's done!"