$SCRIPT_FOLDER = Join-Path $env:USERPROFILE -ChildPath ".ps_profile"

git clone https://github.com/sykuang/ps_profile.git $SCRIPT_FOLDER
Write-Output "Installing windows tools"
winget install -e --silent --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh -s winget
winget install -e --silent --accept-source-agreements --accept-package-agreements fzf
winget install -e --silent --accept-source-agreements --accept-package-agreements sharkdp.fd
winget install -e --silent --accept-source-agreements --accept-package-agreements gerardog.gsudo
winget install -e --silent --accept-source-agreements --accept-package-agreements BurntSushi.ripgrep.MSVC
winget install -e --silent --accept-source-agreements --accept-package-agreements sharkdp.bat
Install-Module -Name PSFzf
Install-Module -Name pins

if (-not(Test-Path -Path $PROFILE -PathType Leaf)){
  New-Item -ItemType SymbolicLink -Path $PROFILE -Target $SCRIPT_FOLDER\Microsoft.PowerShell_profile.ps1
}

Write-Output "Done"
