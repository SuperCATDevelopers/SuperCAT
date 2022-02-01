#!/bin/pwsh

function Set-Time {
    # . SYNOPSIS
    # Provide a wrapper around Set-Date.
    param(
        [Parameter()]
        [switch]$NoPrompt
    )

    if (!$NoPrompt) {
        Write-Host "Setting system time zone to UTC..."
        Set-TimeZone -Id "UTC"
        Write-Host
        Write-Host "================================================"
        Write-Host "The current time is $([datetime]::now.ToUniversalTime().tostring("s")) UTC"
        Write-Host "Is the CMOS battery good and the time accurate?"
        Write-Host "================================================"
        if ($(Read-Intent -TF)) { return Get-Date }
        Write-Host "================================================"
        Write-Host "Would you like to change the system time?"
        Write-Host "================================================"
        if (!$(Read-Intent -TF)) { return Get-Date }
    }
    $read = Read-Host -Prompt "Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS. Ex 2020-01-01T13:39:00"
    Try {
        return Set-Date -Date $([datetime]($read).addminutes($(Get-TimeZone).BaseUtcOffset.TotalMinutes))
    }
    Catch {
        return Set-Time -NoPrompt
    }
}
Export-ModuleMember -Function Set-Time


function Read-Intent {
    # .SYNOPSIS
    # Present a prompt to the user and validate input.
    # .DESCRIPTION
    # Welcome to input validation hell. This function accepts
    # some kind of object and tries to cast it to an array.
    # The array is iterated over to present numbered options to
    # the user, which are then input either singularly or in
    # a list. The user input is validated with regex, then
    # passed back to the calling function as an array of the
    # selected items. Can also handle basic True/False
    # validation for smaller prompts.
    param (
        [Parameter(Mandatory=$True, Position = 0, ParameterSetName = "Number")]
        $Options,

        [Parameter(Position = 1, ParameterSetName = "Number")]
        [String]$Prompt,

        [Parameter(ParameterSetName = "Number")]
        [Switch]$Multiple,

        [Parameter(ParameterSetName = "TF", Mandatory=$True)]
        [Switch]$TF
    )

    ## True/False Validation
    if ($TF) {
        $Result = Read-Host -Prompt "(y/n)"
        while ( -not (@("y","n","yes","no") -eq $Result) ) {
            $Result = Read-Host -Prompt "Please enter yes or no"
        }
        Write-Host
        if ( @("y","yes") -eq $Result ) { return $True }
        else { return $False }
    }

    function Get-Duplicate {
        param (
            [Parameter(Mandatory=$True, Position = 0, ValueFromPipeline=$True)]
            [Array]$Array
        )
        $Hashtable = @{}
        $Array | ForEach-Object { $Hashtable[$_] = "" }
        if ($Hashtable.Count -eq $Array.Count) { return $False }
        else { return $True }
    }

    ## Attempt to cast the input to an array
    $OptionArray = $([array]($Options))

    ## Present Options to User
    Write-Host
    Write-Host "================================================"
    if ( $Null -ne $PSBoundParameters.Prompt ) {
        Write-Host $Prompt
    }
    if ($Multiple) {
        Write-Host "Please select one or more of the following,"
        Write-Host "inputting only numbers and commas (i.e. 1,25,6):"
    }
    else {
        Write-Host "Input the associated number (i.e $($OptionArray.Count - 1)):"
    }
    Write-Host
    for ($i=0; $i -lt $OptionArray.Count; $i++) {
        Write-Host $i "=" $OptionArray[$i]
    }
    Write-Host "================================================"

    ## Input Validation
    if ($Multiple) {
        while ($True) {
            $Result = Read-Host -Prompt "Select"
            $ResultList = $Result.Split(",")
            if ($Result -notmatch "^\d+(,\d+)*$") {
                Write-Host "Please only input numbers and commas (i.e. 1,25,6)"
            }
            elseif (( [int[]]$ResultList -ge $OptionArray.Count ) -or ( $ResultList -lt 0 )) {
                Write-Host "Please ensure your entry is between 0 and $($OptionArray.Count - 1)"
            }
            elseif ($(Get-Duplicate $ResultList)) {
                Write-Host "Please ensure there are no duplicates in your entry."
            }
            else {
                Write-Host
                return $OptionArray[$ResultList]
            }
        }
    }
    else {
        while ($True) {
            $Result = Read-Host -Prompt "Select"
            if ($Result -notmatch "\d+") {
                Write-Host "Please only input one number (i.e. $($OptionArray.Count - 1))"
            }
            elseif (( [int]$Result -ge $OptionArray.Count ) -or ( $Result -lt 0 )) {
                Write-Host "Please ensure your entry is between 0 and $($OptionArray.Count -1)"
            }
            else {
                Write-Host
                return $OptionArray[$Result]
            }
        }
    }
}
Export-ModuleMember -Function Read-Intent

function Read-CSV {
    # .SYNOPSIS
    # Pull an arbitrary CSV and request the user to pick a row from the
    # given column.
    param (
        [Parameter(Mandatory=$True,Position=0,ParameterSetName="Default")]
        [Parameter(Mandatory=$True,Position=0,ParameterSetName="Select")]
        [ValidateNotNullOrEmpty()]
        [String]$CSVPath,
        
        [Parameter(Mandatory=$True,Position=1,ParameterSetName="Default")]
        [Parameter(Mandatory=$True,Position=1,ParameterSetName="Select")]
        [ValidateNotNullOrEmpty()]
        [String]$Column,
        
        [Parameter(Position=2,Mandatory=$True,ParameterSetName="Select")]
        [ValidateNotNullOrEmpty()]
        [String]$Select,
        
        [Parameter(Position=3,Mandatory=$True,ParameterSetName="Select")]
        [PSCustomObject]$Config
    )
    Try {
        $CSV = Import-CSV -Path $CSVPath
    } Catch {
        throw "$CSVPath doesn't exist! Please reinstall SuperCAT or populate the list."
    }
    if ($Select) {
        return $(if ($( $entry = $CSV | Where-Object {
                $_.Select -eq $Config.KnownDrives.$($Config.LastHDD).Select}).Select) {
            $entry
        } else {
            "ZZ"
        })
    }
    $result = $(Read-Intent $CSV.$Column "What is is the $Column?")
    return $(if ( $result -eq "Other") {
        $(Read-Host -Prompt "What is the $Column")
    } else {
        $result
    })
}
Export-ModuleMember -Function Read-CSV

Try {
    Get-Command pause -ErrorAction Stop | Out-Null
}
Catch {
    function pause {
        # .SYNOPSIS
        # Provides pause function
        Read-Host -Prompt "Press enter to continue" | Out-Null
    }
    Export-ModuleMember -Function pause
}
