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
    $script:Settings = Get-Content $ConfigFile | ConvertFrom-Json
}

function _GetAssertHomeDir {
    $HomeDir = $script:Settings.HomeDir

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
    $Method = $script:Settings.Method
    if (-not ($Method -in $MethodOptions)) {
        Write-Host "Unknown venv method: $Method`nReplace in config file with one of: $($MethodOptions)"
        exit 1
    }
    Return $Method
}
