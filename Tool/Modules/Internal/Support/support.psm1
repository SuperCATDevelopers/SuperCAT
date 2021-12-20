#!/bin/pwsh

function Get-TimeDelta {
    param(
        [Parameter()]
        [switch]$Trust,

        [Parameter()]
        [switch]$NoPrompt
    )
    if ($Trust) { return New-TimeSpan }
    if (!$NoPrompt) {
        Write-Host "Is the CMOS battery good and the time accurate?"
        if ($(Read-Intent -TF)) { return New-TimeSpan }
    }
    $read = Read-Host -Prompt "Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS. Ex 2020-01-01T13:39:00"
    Try {
        return New-TimeSpan -End $([datetime]($read))
    }
    Catch {
        ## Using a recursive function probably isn't best practice.
        ## Anyone who wants to reimplement this, please do.
        return Get-TimeDelta -NoPrompt
    }
}

function Get-ActualDate {
    # .SYNOPSIS
    # Output the system time plus the current delta.
    param(
        [Parameter()]
        [switch]$Trust
    )
    if ($Trust) {
        return (Get-Date)
    }
    else {
    	try {
        	return (Get-Date) + $UserTime
	}
	catch {
		return (Get-Date) ## Blank dates confuse Win 7.
	}
    }
}

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
    Clear-Host
    Write-Host "================================================"
    if ( $Null -eq $Prompt ) {
        Write-Host $Prompt
        Write-Host
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
                Write-Host "Please only input numbers and commas (eg 1,25,6)"
            }
            elseif (( $ResultList -ge $OptionArray.Count ) -or ( $ResultList -lt 0 )) {
                Write-Host "Please ensure your entry is between 0 and $($OptionArray.Count - 1)"
            }
            else {
                return $OptionArray[$ResultList] ## You can use an array to select items in an array. Handy!
            }
        }
    }
    else {
        while ($True) {
            $Result = Read-Host -Prompt "Select"
            if ($Result -notmatch "\d+") {
                Write-Host "Please only input numbers and commas (eg 1,25,6)"
            }
            elseif (( $Result -ge $OptionArray.Count ) -or ( $Result -lt 0 )) {
                Write-Host "Please ensure your entry is between 0 and $($OptionArray.Count)"
            }
            else {
                return $OptionArray[$Result]
            }
        }
    }
}
