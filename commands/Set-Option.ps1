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