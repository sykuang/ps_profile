oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_modern.omp.json" | Invoke-Expression

Import-Module PSReadLine

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
New-Alias open ii
New-Alias .. "cd.."
New-Alias vim "nvim"
function cdc {set-location C:\}
function cdd {set-location D:\}
function cde {set-location E:\}
function cat([string]$filename){
    pygmentize.bat  $filename
}
function ... { set-location ..\.. }
function cdsrc { set-location E:\src }
function codeg([string]$filename){
    code --goto $filename
}
function rgcpp([string]$filename){
    rg --type cpp $filename
}
function md5sum([string]$filename){
    certutil -hashfile $filename MD5
}
