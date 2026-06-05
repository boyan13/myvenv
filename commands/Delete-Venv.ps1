function Delete-Venv {
    <#
    .DESCRIPTION
        Deletes a myvenv-managed venv. 

        A confirmation prompt showing the full path 
        to be removed is displayed before deletion 
        takes place.
        
        Usage:      delete $Name

        Remarks:    The function will check the matched venv 
                    directory for the existence of pyvenv.cfg 
                    as described by the PEP 405 venv standard.
                    This is done to prevent accidental deletions 
                    of non-venvs.
    #>

    param (
        [Parameter(Position=0, Mandatory=$true)][string]$Name
    )

    # Validate mandatory arguments present.
    if (($null -eq $Name) -or ("" -eq $Name)) {
        Write-Host '$Name is a mandatory argument.'
        exit 1
    }

    # Read the path of the directory where the Python virtual environments live.
    $HomeDir = _GetAssertHomeDir

    # Check for some weird symbols that might cause the path to break out from the virtualenv directory.
    if (
        ($Name -match '\\') -OR 
        ($Name -match '/') -OR 
        ($Name -match '\.') -OR 
        ($Name -match '%')
    ) { 
        Write-Host "Cancelling because name contains suspicious symbols."
        exit 2
    }

    # Build the full path to the virtualenv directory to delete.
    $DeletePath = Join-Path "$HomeDir" -ChildPath "$Name"

    if (-not (Test-Path $DeletePath)) {
        Write-Host "Venv not found."
        exit 3
    }

    if (-not (Test-Path (Join-Path $DeletePath -ChildPath "pyvenv.cfg"))) {
        Write-Host "Quick venv check failed! Aborting."
        exit 4
    }

    # Prompt a warning and display the path to be deleted.
    Write-Warning "You are about to delete $DeletePath."
    $response = Read-Host "Continue? (y/n)"
    if ($response -ne "y") {
        Write-Host "Cancelled"
        exit 0
    } else{
        # Delete recursively.
        Remove-Item -Recurse $DeletePath
    }
}