oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kushal.omp.json" | Invoke-Expression

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
    $version = Get-ChildItem "C:\Program Files\Microsoft Visual Studio\" -Directory | Where-Object { $_.Name -like "20*" } | Sort-Object -Descending | Select-Object -First 1
    if ($null -eq $version) {
        Write-Output "No Visual Studio found"
        return
    }
    $distrubted = Get-ChildItem "$version" -Directory | Where-Object { $_.Name -like "Enterprise" } | Sort-Object -Descending | Select-Object -First 1
    if ($null -eq $distrubted) {
        $distrubted = Get-ChildItem "$version" -Directory | Where-Object { $_.Name -like "Professional" } | Sort-Object -Descending | Select-Object -First 1
    }
    if ($null -eq $distrubted) {
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
    elseif ($OSArchitecture.contains("ARM")) {
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
    Set-Location $OldPWD
}
function upgradeProfile {
   Set-Location $HOME\.ps_profile
   git pull 
}
function scmd{
    param(
        [Parameter(Position=0,mandatory=$true)]
        [string]$cmd,
        [Parameter(
            Mandatory=$false,
            ValueFromRemainingArguments=$true,
            Position = 1
        )][string[]]
        $listArgs
    )
    $scmd_path = Join-Path -path ${HOME} -ChildPath .scmd
    if (!(Test-Path $scmd_path)){
        git clone https://github.com/sykuang/scmd.git $scmd_path
    }
    $cmd_path = Join-Path -path $scmd_path -ChildPath "$cmd.ps1"
    if (!(Test-Path $cmd_path)){
        Write-Output "try upgrade scmd"
        Set-Location $scmd_path
        git pull
    }
    if (!(Test-Path $cmd_path)){
        Write-Output "Command not found, please check"
        return
    }
    . $cmd_path $listArgs
}
if (Test-Path $HOME\ps_env.ps1) {
    . $HOME\ps_env.ps1
}