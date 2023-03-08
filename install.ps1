$SCRIPT_PATH = $MyInvocation.MyCommand.Path
$SCRIPT_FOLDER = Split-Path $SCRIPT_PATH -Parent

New-Item -ItemType SymbolicLink -Path $PROFILE -Target $SCRIPT_FOLDER\Microsoft.PowerShell_profile.ps1
