function Create-Venv {
    <#
    .DESCRIPTION
        Creates a venv in the myvenv-managed directory.

        Usage:      create $Name [$Python $RequirementsFile]

        Options:
            $Python     If supplied, python will be invoked via py 
                        launcher (or python installation manager), 
                        otherwise the script tries to invoke "python.exe" 
                        from path.
            $(Require   If supplied, the requirements file will be used
            mentsFile)  to install dependencies on the venv.
                            
    #>

    param(
        [String]$Name,  # The new virtualenv's name
        [String]$Python,  # Py launcher's version arg.
        [String]$RequirementsFile  # Path to a requirements.txt.
    )

    # Validate mandatory arguments present.
    if (($null -eq $Name) -or ("" -eq $Name)) {
        Write-Host '$Name is a mandatory argument.'
        exit 1
    }

    # Get venv home dir from env variable.
    $HomeDir = _GetAssertHomeDir

    # Check if venv with name exists.
    $OutDir = Join-Path $HomeDir $Name
    if (Test-Path $OutDir) {
        Write-Host "Venv already exists."
        exit 1
    }

    $Method = _GetAssertMethod

    # Get abs path of python to use.
    # Either path python or py launcher one specified by version.
    if ($Python.Length -eq 0) {
        $PythonExe = (Get-Command python).Source
    } else {
        $PythonExe = & py "-$Python" -c "import sys; print(sys.executable)"
    }

    Write-Host "`nUsing $PythonExe`nUsing $Method`nCreating venv at $OutDir`n"

    # Create venv.
    if ($Method -eq "venv") {
        & "$PythonExe" -m venv "$OutDir"
    } elseif ($Method -eq "virtualenv") {
        & $PythonExe -m virtualenv "$OutDir"
    } else {
        Write-Host "Unhandled venv method: $Method"
    }

    # Install packages if requirements.txt specified.
    # The VIRTUAL_ENV var contains the path to the current venv if one is active.
    if ($RequirementsFile.Length -gt 0) {
        Write-Host "`nInstalling requirements from $RequirementsFile`n`n"  # Log.
        $ActivateScript = Join-Path $OutDir "Scripts\activate.ps1"
        . $ActivateScript
        if ($env:VIRTUAL_ENV -eq $OutDir) {
            python.exe -m pip install -r "$RequirementsFile"   # Install.
            . "deactivate"
        } else {
            Write-Host "Failed to activate venv. Requirements install aborted."
        }
    }
}