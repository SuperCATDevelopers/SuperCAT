Clear-Host
Write-Output "
===============================================================
This script helps automate the creation of the config.json file
used by the Cyber Assessment Tool (CAT). Whenever changes are
needed for the file, you can either edit the variables within
the file or you can use this script again to create it.
==============================================================="
pause

while(!($Basecheck -eq 1)){
    $Base = Read-Host "Type in the name of your base"

    Write-Output "
    ===============================================================
    You inputted $Base . Is this correct?
    1 = Yes
    2 = No
    ==============================================================="
    $BaseCheck = Read-Host
}

while(!($SystemCheck -eq 1)){
    Clear-Host
    $System1 = Read-Host "Type in the first common system you will be assessing"
    $System2 = Read-Host "Type in the second common system you will be assessing"
    $System3 = Read-Host "Type in the third common system you will be assessing"
    $System4 = Read-Host "Type in the fourth common system you will be assessing"
    $System5 = Read-Host "Type in the fifth common system you will be assessing"

    Write-Output "
    ===============================================================
    You inputted:
    $System1
    $System2
    $System3
    $System4
    $System5
    1 = Yes
    2 = No
    ==============================================================="
    $SystemCheck = Read-Host
}

while(!($LocationCheck -eq 1)){
    Clear-Host
    $Location1 = Read-Host "Type in the first common location you will be assessing"
    $Location2 = Read-Host "Type in the second common location you will be assessing"
    $Location3 = Read-Host "Type in the third common location you will be assessing"
    $Location4 = Read-Host "Type in the fourth common location you will be assessing"
    $Location5 = Read-Host "Type in the fifth common location you will be assessing"

    Write-Output "
    ===============================================================
    You inputted:
    $Location1
    $Location2
    $Location3
    $Location4
    $Location5
    1 = Yes
    2 = No
    ==============================================================="
    $LocationCheck = Read-Host
}


$Output = @{
    BaseName = $Base
    System1 = $System1
    System2 = $System2
    System3 = $System3
    System4 = $System4
    System5 = $System5
    Location1 = $Location1
    Location2 = $Location2
    Location3 = $Location3
    Location4 = $Location4
    Location5 = $Location5
} | ConvertTo-JSON | Set-Content -Path "Tool/config.json"

Write-Output "config.json has been created!"