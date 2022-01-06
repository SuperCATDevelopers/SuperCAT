function Start-SCAP {
    # .SYNOPSIS
    # Conducts a SCAP check on the machine and writes it to a file
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$RootDirectory,

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$Directory
    )

    if (!$(Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null }
    if(test-path "$RootDirectory\Scripts\SCAP\cscc.exe"){
        Write-Host "Running SCAP scan, please be patient."
        Try{
            Start-Process -FilePath "$RootDirectory\Scripts\SCAP\cscc.exe" -ArgumentList "-u $Directory"
        } Catch {
            Write-Error "SCAP cscc.exe not found or invalid."
            Write-Error "$_"
        }
    }
}
Export-ModuleMember -Function Start-SCAP
