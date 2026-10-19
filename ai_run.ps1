param([Parameter(Position=0)][string]$Question = "")
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\ai.ps1"

if ([Console]::IsInputRedirected) {
    $stdin = [Console]::In.ReadToEnd()
    $stdin | ai $Question
} else {
    ai $Question
}
