param([Parameter(Position=0)][string]$Question = "")
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\ai.ps1"
$stdinLines = @($input)
if ($stdinLines.Count -gt 0) {
    $stdinLines | ai $Question
} else {
    ai $Question
}
