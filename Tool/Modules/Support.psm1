#!/bin/pwsh

function Set-Time {
    # . SYNOPSIS
    # Provide a wrapper around Set-Date.
    param(
        [Parameter()]
        [switch]$NoInitial,
        [Parameter(Position=0)]
        [string]$time
    )
    if (!$NoInitial) {
        Write-Host "Setting system time zone to UTC..."
        Set-TimeZone -Id "UTC"
    }
    if (!($NoInitial -or ($time))) {
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
    if ($time) {
        if ($time -eq "trust") { return Get-Date }
        Try {
            return Set-Date -Date $([datetime]($time).addminutes($(Get-TimeZone).BaseUtcOffset.TotalMinutes))
        }
        Catch {
            throw "Incorrect time format! Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS. Ex 2020-01-01T13:39:00"
        }
    }
    $read = Read-Host -Prompt "Please enter the UTC date and time in the format YYYY-MM-DDTHH:MM:SS. Ex 2020-01-01T13:39:00"
    Try {
        return Set-Date -Date $([datetime]($read).addminutes($(Get-TimeZone).BaseUtcOffset.TotalMinutes))
    }
    Catch {
        return Set-Time -NoInitial
    }
}
Export-ModuleMember -Function Set-Time

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
Export-ModuleMember -Function Get-Duplicate

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

    for (($Page=1),
    ($ShortList=$([array]($Options))[0..9]),
    ($LastPage=[math]::Ceiling($([array]($Options)).count/10));$True;) {
        Write-Host
        Write-Host "================================================"
        if ($Prompt) {
            Write-Host $Prompt
        }
        Write-Host "Input the associated number (i.e $($ShortList.Count - 1)):"
        Write-Host
        for ($i=0; $i -lt $ShortList.Count; $i++) {
            Write-Host $i "=" $ShortList[$i]
        }
        Write-Host
        Write-Host "Page" $Page "of" $([string]$LastPage).PadRight(3," ") "    p for previous, n for next"
        Write-Host "================================================"
        :switchloop while ($True) {
            $Result = Read-Host -Prompt "Select"
            Switch ($Result) {
                {$_ -notmatch "^\d+$|^[zxnp]$"} {
                    if ($LastPage -eq 1) {
                        Write-Host "Please only input one number (i.e. $($ShortList.Count - 1))"
                    } else {
                        Write-Host "Please enter a number between 0 and $($ShortList.Count - 1) or the"
                        Write-Host "charters n or p for next page and previous page respectively."
                    }
                    Break
                }
                {$_ -match "^[zp]$"} {
                    if ($Page -eq 1) {
                        Write-Host "You're on the first page."
                        Break
                    } else {
                        $Page--
                        $ShortList=$([array]($Options))[(($Page-1)*10)..($Page*10-1)]
                        Break switchloop
                    }
                }
                {$_ -match "^[xn]$"} {
                    if (!($LastPage-$Page)) {
                        Write-Host "You're on the last page."
                        Break
                    } else {
                        $Page++
                        $ShortList=$([array]($Options))[(($Page-1)*10)..($Page*10-1)]
                        Break switchloop
                    }
                }
                {$([int]$_) -lt 0} {continue}
                {$([int]$_) -ge $ShortList.Count} {
                    Write-Host "Please ensure your entry is between 0 and $($ShortList.Count -1)."
                    Break
                }
                Default {
                    Write-Host "Switch term     = " $_
                    Write-Host "ShortList.Count = " $ShortList.Count
                    return $ShortList[$_]
                }
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
