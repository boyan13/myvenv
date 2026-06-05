function Activate-Venv {
    <#
    .DESCRIPTION
        Activates a venv from the managed directory.

        Usage:      activte $Name
    #>

    param (
        [string]$Name
    )
    
    # Validate mandatory arguments present.
    if (($null -eq $Name) -or ("" -eq $Name)) {
        Write-Host '$Name is a mandatory argument.'
        exit 1
    }

    $HomeDir = _GetAssertHomeDir
    & $HomeDir/$Name/Scripts/activate.ps1
}