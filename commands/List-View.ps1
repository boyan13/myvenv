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