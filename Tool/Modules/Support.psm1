#!/bin/pwsh

function Set-Time {
    # . SYNOPSIS
    # Provide a wrapper around Set-Date.
    param(
        [Parameter()]
        [switch]$NoPrompt
    )

    if (!$NoPrompt) {
        Write-Host
        Set-TimeZone -Id "UTC"
        Write-Host "The current time is $([datetime]::now.ToUniversalTime().tostring("s")) UTC"
        Write-Host "Is the CMOS battery good and the time accurate?"
        if ($(Read-Intent -TF)) { return Get-Date }
        Write-Host "Would you like to change the system time?"
        if (!$(Read-Intent -TF)) { return Get-Date }
    }
    $read = Read-Host -Prompt "Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS. Ex 2020-01-01T13:39:00"
    Try {
        return Set-Date -Date $([datetime]($read))
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
        [string]$Prompt,

        [Parameter(ParameterSetName = "Number")]
        [switch]$Multiple,

        [Parameter(ParameterSetName = "TF", Mandatory=$True)]
        [switch]$TF
    )

    ## True/False Validation
    if ($TF) {
        $Result = Read-Host -Prompt "(y/n)"
        while ( -not (@("y","n","yes","no") -eq $Result) ) {
            $Result = Read-Host -Prompt "Please enter yes or no"
        }
        if ( @("y","yes") -eq $Result ) { return $True }
        else { return $False }
    }

    ## Attempt to cast the input to an array
    $OptionArray = $([array]($Options))

    ## Present Options to User
    #  Clear-Host
    Write-Host
    Write-Host
    Write-Host "================================================"
    if ( $Null -ne $PSBoundParameters.Prompt ) {
        Write-Host $Prompt
    }
    if ($Multiple) {
        Write-Host "Input only numbers and commas (i.e. 1,3,4,5):"
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
            elseif (( $ResultList -ge $OptionArray.Count ) -or ( $ResultList -lt 0 )) {
                Write-Host "Please ensure your entry is between 0 and $($OptionArray.Count - 1)"
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
            elseif (( $Result -ge $OptionArray.Count ) -or ( $Result -lt 0 )) {
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
