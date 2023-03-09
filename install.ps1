$SCRIPT_PATH = $MyInvocation.MyCommand.Path
$SCRIPT_FOLDER = Split-Path $SCRIPT_PATH -Parent

Write-Output "Installing windows tools"
winget install JanDeDobbeleer.OhMyPosh -s winget
winget install fzf
winget install sharkdp.fd
winget install gerardog.gsudo
BurntSushi.ripgrep.MSVC
Install-Module -Name PSFzf

if (-not(Test-Path -Path $PROFILE -PathType Leaf)){
  New-Item -ItemType SymbolicLink -Path $PROFILE -Target $SCRIPT_FOLDER\Microsoft.PowerShell_profile.ps1
}

Write-Output "Done"
