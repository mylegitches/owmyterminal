param([Parameter(Position=0)][string]$Goal = "", [string]$YesFlag = "")
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\ai.ps1"
if ($YesFlag -eq "-Yes") {
    aido $Goal -Yes
} else {
    aido $Goal
}
