# Starship prompt
$env:STARSHIP_CONFIG = Join-Path $PSScriptRoot 'starship.toml'
Invoke-Expression (& 'C:\Program Files\starship\bin\starship.exe' init powershell)

# Configure the line editor synchronously.
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -HistorySearchCursorMovesToEnd -ShowToolTips
if ($Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource History
}
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Lazy-load PSFzf on first use.
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
    Import-Module PSFzf -Global -ErrorAction SilentlyContinue
    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        Invoke-FzfPsReadlineHandlerProvider
    }
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
    Import-Module PSFzf -Global -ErrorAction SilentlyContinue
    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        Invoke-FzfPsReadlineHandlerHistory
    }
}
# Autoenv: auto-activate/deactivate .venv when entering/leaving directories
$global:AutoEnvPreviousVenv = $null
function _AutoEnvCheck {
    $activateScript = Join-Path $PWD ".venv\Scripts\activate.ps1"
    $currentVenv = Join-Path $PWD ".venv"
    if (Test-Path $activateScript) {
        if ($env:VIRTUAL_ENV -ne $currentVenv) {
            $global:AutoEnvPreviousVenv = $env:VIRTUAL_ENV
            . $activateScript
        }
    } elseif ($env:VIRTUAL_ENV) {
        deactivate
        if ($global:AutoEnvPreviousVenv -and (Test-Path "$global:AutoEnvPreviousVenv\Scripts\activate.ps1")) {
            . "$global:AutoEnvPreviousVenv\Scripts\activate.ps1"
            $global:AutoEnvPreviousVenv = $null
        }
    }
}
function Set-LocationWithAutoEnv {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
        [string]$Path
    )
    if ($Path) {
        Microsoft.PowerShell.Management\Set-Location $Path
    } else {
        Microsoft.PowerShell.Management\Set-Location $HOME
    }
    _AutoEnvCheck
}
Set-Alias -Name cd -Value Set-LocationWithAutoEnv -Option AllScope -Force
# Run on profile load for terminals that open directly in a project folder
_AutoEnvCheck

New-Alias .. "cd.."
function cpt { copilot --yolo @args }
function gst { git status }
function gd { git diff }
New-Alias vim "nvim"
function cdc { set-location C:\ }
function cdd { set-location D:\ }
function cde { set-location E:\ }
function ... { set-location ..\.. }
function rgcpp([string]$filename) {
    rg --type cpp $filename
}
function launchDev([string]$arch) {
    $OldPWD = $PWD
    # Use vswhere.exe to find the latest Visual Studio installation
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (!(Test-Path $vswhere)) {
        Write-Output "vswhere.exe not found. Is Visual Studio installed?"
        return
    }
    $installPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ([string]::IsNullOrEmpty($installPath)) {
        # Fallback: find any VS installation without requiring VC tools
        $installPath = & $vswhere -latest -products * -property installationPath
    }
    if ([string]::IsNullOrEmpty($installPath)) {
        Write-Output "No Visual Studio installation found"
        return
    }
    $shell_path = Join-Path -Path $installPath "Common7\Tools\Launch-VsDevShell.ps1"
    if (!(Test-Path $shell_path)) {
        Write-Output "Launch-VsDevShell.ps1 not found at: $shell_path"
        return
    }
    $OSArchitecture = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
    if ($OSArchitecture -eq "64-bit") {
        $HostArch = "amd64"
    }
    elseif ($OSArchitecture -eq "32-bit") {
        $HostArch = "x86"
    }
    elseif ($OSArchitecture.contains("ARM")) {
        $HostArch = "arm64"
    }
    if ($null -eq $arch -or $arch -eq "") {
        $arch = $HostArch
    }
    Write-Output "Launch Target arch: $arch , HostArch : $HostArch"
    if ($HostArch -eq "arm64") {
        & $shell_path -Arch $arch
    }
    else {
        & $shell_path -Arch $arch -HostArch $HostArch
    }
    Set-Location $OldPWD
}
function upgradeProfile {
    Set-Location $HOME\PowerShell
    git pull
}
function scmd {
    param(
        [Parameter(Position = 0, mandatory = $true)]
        [string]$cmd,
        [Parameter(
            Mandatory = $false,
            ValueFromRemainingArguments = $true,
            Position = 1
        )][string[]]
        $listArgs
    )
    $scmd_path = Join-Path -path ${HOME} -ChildPath .scmd
    if (!(Test-Path $scmd_path)) {
        git clone https://github.com/sykuang/scmd.git $scmd_path
    }
    $cmd_path = Join-Path -path $scmd_path -ChildPath "$cmd.ps1"
    if (!(Test-Path $cmd_path)) {
        Write-Output "try upgrade scmd"
        Set-Location $scmd_path
        git pull
    }
    if (!(Test-Path $cmd_path)) {
        Write-Output "Command not found, please check"
        return
    }
    . $cmd_path $listArgs
}
if (Test-Path $HOME\ps_env.ps1) {
    . $HOME\ps_env.ps1
}

# Lazy-load modules on CommandNotFound: pins and PowerToys WinGetCommandNotFound
$global:__WinGetCmdNotFoundLoaded = $false
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($commandName, $eventArgs)

    # Lazy-load pins module for Linux-like commands
    $pinsCmds = @('which', 'cat', 'md5sum', 'open', 'time', 'wget')
    if ($commandName -in $pinsCmds) {
        Import-Module pins -Global -ErrorAction SilentlyContinue
        $eventArgs.StopSearch = $false
        return
    }

    # Lazy-load PowerToys WinGetCommandNotFound on first unknown command
    if (-not $global:__WinGetCmdNotFoundLoaded) {
        $global:__WinGetCmdNotFoundLoaded = $true
        $wingetModule = "C:\Program Files\PowerToys\WinUI3Apps\..\WinGetCommandNotFound.psd1"
        if (Test-Path $wingetModule) {
            Import-Module $wingetModule -Global -ErrorAction SilentlyContinue
        }
    }
}
