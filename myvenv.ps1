param([string]$Command)

$_Version = "1.0.0"
$ConfigDir = [IO.Path]::GetFullPath($HOME)
$DataDir = [IO.Path]::GetFullPath($(Join-Path $HOME "\.myvenv\"))
$ConfigFile = Join-Path $ConfigDir ".myvenv.json"
$API = @{
    "set"         = "Set-Option"
    "get"         = "Get-Option"
    "create"      = "Create-Venv"
    "delete"      = "Delete-Venv"
    "list"        = "List-Venv"
    "activate"    = "Activate-Venv"
}
$MethodOptions = @("venv", "virtualenv")
$DefaultConfig = @{
    HomeDir = $DataDir
    Method = "venv"  # Values: [venv, virtualenv]
}

$global:Settings = $null

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

function List-Venv {
    <#
    .DESCRIPTION
        List all myvenv-managed venvs.

        Usage:      list [-FullPaths]
    #>

    param(
        [Parameter(HelpMessage="Will show the full paths instead of just the virtualenv names.")][Switch]$FullPaths
    )

    $HomeDir = _GetAssertHomeDir

    if ($FullPaths){
        Get-ChildItem -Path $HomeDir -Directory | Select-Object FullName
    } else{
        Get-ChildItem -Path $HomeDir -Directory | Select-Object Name
    }
}

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

function Get-Option {
    <#
    .DESCRIPTION
        Reads persistent settings.

        Usage:      get $Name

        Example:    get HomeDir
        
        For a full list of settings, see help for set. 
    #>

    param([string]$Name)
    
    # Validate mandatory arguments present.
    if (($null -eq $Name) -or ("" -eq $Name)) {
        Write-Host '$Name is a mandatory argument.'
        exit 1
    }
    
    Write-Host "$($global:Settings.$Name)"
}

function Set-Option {
    <#
    .DESCRIPTION
        Manages persistent settings.

        Usage:      set key=value

        Example:    set HomeDir="~/global_venvs"
        
        Options:
            HomeDir     Directory where the venvs are stored 
                        (existing venvs are abandoned).
            Method      Options are "venv" and "virtualenv". 
                        Determines the venv tool to invoke.
    #>

    $Map = _ParseKeyValue($args)
    $Conf = Get-Content $ConfigFile | ConvertFrom-Json 
    foreach ($key in $Map.Keys) {
        if ($DefaultConfig.ContainsKey($key)) {
            $Conf.$key = $Map[$key]
            Write-Host "Success"
        } else {
            Write-Host "Unknown option: $key"
        }
    }
    $Conf | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile
}

function _ParseKeyValue {
    param([string[]]$Arr)
    $Map = @{}
    foreach ($arg in $Arr) {
        if ($arg -match "^(?<key>[^=]+)=(?<value>.+)$") {
            $Map[$Matches['key']] = $Matches['value']
        }
    }
    return $Map
}

function _InitializeEnvironment {
    if (-not (Test-Path $ConfigDir)) {
        Write-Host "Config dir does not exist - creating $ConfigDir"
        New-Item -ItemType Directory -Path $ConfigDir | Out-Null
    }
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Config file does not exist - creating $ConfigFile"
        $defaultConfig | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile
    }
    $global:Settings = Get-Content $ConfigFile | ConvertFrom-Json
}

function _GetAssertCommand{
    param([string]$Command)
    if ($API.ContainsKey($Command)) {
        return $API[$Command]
    } else {
        Write-Host "Unknown command: $Command"
        exit 1
    }
}

function _GetAssertHomeDir {
    $HomeDir = $global:Settings.HomeDir

    # Validate.
    if ($HomeDir -eq $null) {
        Write-Host "Failed to read HomeDir from config file."
        exit 1
    }

    try {
        [System.IO.Path]::GetFullPath($HomeDir.Replace("~", $HOME)) | Out-Null
    } catch {
        Write-Host "Warning: HomeDir is invalid. Please change it."
        exit 2
    }

    # Prompt user for permissions to create the venvs dir.
    if (-not (Test-Path $HomeDir -PathType Container)) {
        Write-Warning "Venvs dir does not exist. Create `"$HomeDir`"?"
        $response = Read-Host "Continue? (y/n)"
        if ($response -ne "y") {
            Write-Host "Cancelled"
            exit 0
        } else {
            Write-Host "Creating $HomeDir"
            New-Item -ItemType Directory -Path $HomeDir | Out-Null
        }
    }

    Return (Resolve-Path -Path $HomeDir).Path
}

function _GetAssertMethod {
    $Method = $global:Settings.Method
    if (-not ($Method -in $MethodOptions)) {
        Write-Host "Unknown venv method: $Method`nReplace in config file with one of: $($MethodOptions)"
        exit 1
    }
    Return $Method
}

function _HandleHelp {
    if ((-not $Command) -or (($Command -eq "help") -and ($args.Count -eq 0))) {
        $AllCommands = ""
        ForEach ($key in @($API.Keys) + "help" | Sort-Object) {
            if ($AllCommands -eq "") {
                $AllCommands = $AllCommands + "$key"
            } else {
                $AllCommands = $AllCommands + "`n                $key"
            }
        }

        Write-Host @"

MyVenv version $_Version

Syntax:         myvenv COMMAND [arg1 arg2 arg3 ...]

Help:           myvenv help COMMAND

Basic usage:    myvenv create <NAME>
                myvenv activate <NAME>
                myvenv delete <NAME>

Commands:       $AllCommands

"@
        exit 0
    } elseif ($Command -eq "help") {
        $InternalCommand = _GetAssertCommand($args[0])
        "`n" + ((Get-Help $InternalCommand).Description | ForEach-Object { $_.Text }) + "`n" | Write-Host
        # if ($args.Count -gt 1) {
        #     $subargs = $args[1..($args.Count-1)]
        #     Get-Help $InternalCommand @subargs
        # } else {
        #     Get-Help $InternalCommand
        # }
        exit 0
    }
}

# MAIN

$ErrorActionPreference = "Stop"  # Cancel script execution on error.
_HandleHelp @args
$InternalCommand = _GetAssertCommand($Command)
_InitializeEnvironment 
& $InternalCommand @args
