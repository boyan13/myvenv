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
    
    Write-Host "$($script:Settings.$Name)"
}