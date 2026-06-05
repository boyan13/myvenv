param([string]$Command)

$_Version = "1.0.1"
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

$script:Settings = $null

function _GetAssertCommand{
    param([string]$Command)
    if ($API.ContainsKey($Command)) {
        return $API[$Command]
    } else {
        Write-Host "Unknown command: $Command"
        exit 1
    }
}

# MAIN

Get-ChildItem -Path `
    "$PSScriptRoot\commands",
    "$PSScriptRoot\utils" `
    -Filter *.ps1 | 
    ForEach-Object {. $_.FullName}

$ErrorActionPreference = "Stop"  # Cancel script execution on error.
_HandleHelp @args  # Handle special help command.
$InternalCommand = _GetAssertCommand($Command)  # Assert provided command exists.
_InitializeEnvironment  # Initialize environment (load/create settings file, venv dir, etc).
& $InternalCommand @args  # Execute command with arguments.
