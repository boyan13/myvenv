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