# Oh-My-Posh: Use cached init script for faster startup
$ohMyPoshTheme = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/kushal.omp.json"
$ohMyPoshCache = "$HOME\.oh-my-posh-init.ps1"
if (Test-Path $ohMyPoshCache) {
    . $ohMyPoshCache
} else {
    oh-my-posh init pwsh --config $ohMyPoshTheme | Invoke-Expression
}

function Update-OhMyPoshCache {
    oh-my-posh init pwsh --config $ohMyPoshTheme --print > "$HOME\.oh-my-posh-init.ps1"
    Write-Host "Oh-My-Posh cache updated. Restart shell to apply." -ForegroundColor Green
}

# PSReadLine and PSFzf: Lazy-load using ThreadJob and OnIdle event
$null = Start-ThreadJob -Name 'ProfileInit' -ScriptBlock {
    Import-Module PSReadLine
}

$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module PSReadLine
    # Shows navigable menu of all options when hitting Tab
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Autocompletion for Arrow keys
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    Set-PSReadLineOption -ShowToolTips
    # Fish-like Autosuggestion in Powershell
    Set-PSReadLineOption -PredictionSource History

    # Lazy-load PSFzf: Import on first Ctrl+t or Ctrl+r
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
}
New-Alias .. "cd.."
function cdc { set-location C:\ }
function cdd { set-location D:\ }
function cde { set-location E:\ }
function ... { set-location ..\.. }
function codeg([string]$filename, [int]$line) {
    code --goto ${filename}:${line}
}
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
    Set-Location $HOME\.ps_profile
    git pull
    Update-OhMyPoshCache
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

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
