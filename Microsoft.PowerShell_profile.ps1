oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_modern.omp.json" | Invoke-Expression

# Import module
Import-Module PSReadLine
Import-Module pins

# Shows navigable menu of all options when hitting Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompleteion for Arrow keys
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -ShowToolTips
# Set FZF option
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
# Fish-like Autosuggestion in Powershell
Set-PSReadLineOption -PredictionSource History
New-Alias .. "cd.."
New-Alias vim "nvim"
function cdc { set-location C:\ }
function cdd { set-location D:\ }
function cde { set-location E:\ }
function ... { set-location ..\.. }
function cdsrc { set-location E:\src }
function codeg([string]$filename) {
    code --goto $filename
}
function rgcpp([string]$filename) {
    rg --type cpp $filename
}
function launchDev([string]$arch) {
    $OldPWD = $PWD
    $version = Get-ChildItem "C:\Program Files\Microsoft Visual Studio\" -Directory | Where-Object { $_.Name -like "20*" } | Sort-Object -Descending | Select-Object -First 1
    $distrubted = Get-ChildItem "$version" -Directory | Where-Object { $_.Name -like "Enterprise" } | Sort-Object -Descending | Select-Object -First 1
    if ($distrubted -eq $null) {
        $distrubted = Get-ChildItem "$version" -Directory | Where-Object { $_.Name -like "Professional" } | Sort-Object -Descending | Select-Object -First 1
    }
    if ($distrubted -eq $null) {
        $distrubted = Get-ChildItem "$version" -Directory | Where-Object { $_.Name -like "Community" } | Sort-Object -Descending | Select-Object -First 1
    }
    # Check if the path exists
    $shell_path = Join-Path -path $distrubted "Common7\Tools\Launch-VsDevShell.ps1"
    $OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object    OSArchitecture -ErrorAction Stop).OSArchitecture
    if ($OSArchitecture -eq "64-bit") {
        $HostArch = "amd64"
    }
    elseif ($OSArchitecture -eq "32-bit") {
        $HostArch = "x86"
    }
    elseif ($OSArchitecture -eq "ARM 64-bit Processor") {
        $HostArch = "arm64"
    }
    if ($arch -eq $null -or $arch -eq "") {
        $arch = $HostArch
    }
    Write-Output "Launch Target arch: $arch , HostArch : $HostArch"
    if (Test-Path $shell_path) {
        if ($HostArch -eq "arm64") {
            & $shell_path -Arch $arch
        }
        else {
            & $shell_path -Arch $arch -HostArch $HostArch
        }
    }
    cd $OldPWD
}
if (Test-Path $HOME\ps_env.ps1) {
    . $HOME\ps_env.ps1
}