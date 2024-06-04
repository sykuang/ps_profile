$SCRIPT_FOLDER = Join-Path $env:USERPROFILE -ChildPath ".ps_profile"
function enableDeveloper {
  if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1"
    Exit
  }
  else {
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1
  }
}
function installPorfile {
  try {
    if (-not(Test-Path -Path $SCRIPT_FOLDER -PathType Leaf)) {
      git clone https://github.com/sykuang/ps_profile.git $SCRIPT_FOLDER
    }
  }
  catch [System.Management.Automation.CommandNotFoundException] {
    winget install -e --silent --accept-source-agreements --accept-package-agreements Git.Git
    Write-Output "Please restart the script with new windows terminal or powershell"
    exit
  }
  if (-not(Test-Path -Path $PROFILE -PathType Leaf)) {
    New-Item -Force -ItemType SymbolicLink -Path $PROFILE -Target $SCRIPT_FOLDER\Microsoft.PowerShell_profile.ps1
  }
}
function installModules {
  Write-Output "Installing windows tools"
  winget install -e --silent --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh -s winget
  winget install -e --silent --accept-source-agreements --accept-package-agreements fzf
  winget install -e --silent --accept-source-agreements --accept-package-agreements sharkdp.fd
  winget install -e --silent --accept-source-agreements --accept-package-agreements gerardog.gsudo
  winget install -e --silent --accept-source-agreements --accept-package-agreements BurntSushi.ripgrep.MSVC
  winget install -e --silent --accept-source-agreements --accept-package-agreements sharkdp.bat
  Install-Module -AcceptLicense -Name PSFzf
  Install-Module -AcceptLicense -Name pins
}

function installFiraCode {
  # Download fonts
  Invoke-WebRequest -Uri https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip -OutFile FiraCode.zip
  # Install fonts
  Expand-Archive -Path FiraCode.zip -DestinationPath FiraCode
  $SourceDir = ".\FiraCode"
  $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)

  Get-ChildItem -Path $SourceDir -Include '*.ttf', '*.ttc', '*.otf' -Recurse | ForEach {
    $Destination.CopyHere($_.FullName, 0x10)
  }
  Remove-Item -Recurse .\FiraCode
  Remove-Item .\FiraCode.zip

 
}
enableDeveloper
installPorfile
installModules
installFiraCode
Write-Output "Done"
