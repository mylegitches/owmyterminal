param([Parameter(Position=0)][string]$Goal = "", [switch]$Yes)
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\ai.ps1"
aido $Goal -Yes:$Yes
