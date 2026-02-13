param()
$SCRIPT_FOLDER = Join-Path $env:USERPROFILE -ChildPath "PowerShell"

function installProfile {
  try {
    if (-not(Test-Path -Path $SCRIPT_FOLDER -PathType Container)) {
      git clone https://github.com/sykuang/ps_profile.git $SCRIPT_FOLDER
    }
  }
  catch [System.Management.Automation.CommandNotFoundException] {
    winget install -e --silent --accept-source-agreements --accept-package-agreements Git.Git
    Write-Output "Git installed. Refreshing PATH..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    git clone https://github.com/sykuang/ps_profile.git $SCRIPT_FOLDER
  }
  if (-not(Test-Path -Path $PROFILE -PathType Leaf)) {
    # Point Documents back to local path (not OneDrive) so $PROFILE resolves to the cloned repo
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal" -Value "%USERPROFILE%\"
    Write-Output "Profile path has been configured."
  }
}
function installModules {
  Write-Output "Installing windows tools"
  winget install -e --silent --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh -s winget
  winget install -e --silent --accept-source-agreements --accept-package-agreements junegunn.fzf
  winget install -e --silent --accept-source-agreements --accept-package-agreements sharkdp.fd
  winget install -e --silent --accept-source-agreements --accept-package-agreements gerardog.gsudo
  winget install -e --silent --accept-source-agreements --accept-package-agreements BurntSushi.ripgrep.MSVC
  winget install -e --silent --accept-source-agreements --accept-package-agreements sharkdp.bat
  # Install PS modules in a new pwsh process so the modified profile path is active
  Start-Process -FilePath pwsh -ArgumentList "-NoProfile", "-Command", "Install-Module -Force -AcceptLicense -Scope CurrentUser -Name PSFzf; Install-Module -Force -AcceptLicense -Scope CurrentUser -Name pins" -Wait
}

function installFiraCode {
  $tempDir = Join-Path $env:TEMP "FiraCodeInstall"
  $zipFile = Join-Path $tempDir "FiraCode.zip"
  $extractDir = Join-Path $tempDir "FiraCode"
  try {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    # Download fonts
    Write-Output "Downloading FiraCode Nerd Font..."
    Invoke-WebRequest -Uri https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip -OutFile $zipFile
    # Install fonts
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
    $FontsFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (-not (Test-Path $FontsFolder)) { New-Item -ItemType Directory -Path $FontsFolder -Force | Out-Null }

    Get-ChildItem -Path $extractDir -Include '*.ttf', '*.ttc', '*.otf' -Recurse | ForEach-Object {
      $fontPath = Join-Path $FontsFolder $_.Name
      Copy-Item -Path $_.FullName -Destination $fontPath -Force
      # Register font in user registry
      $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
      $fontName = $_.BaseName
      New-ItemProperty -Path $regPath -Name $fontName -Value $fontPath -PropertyType String -Force | Out-Null
    }
    Write-Output "FiraCode Nerd Font installed successfully."
  }
  finally {
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
  }
}
installProfile
installModules
installFiraCode
Write-Output "Done"
