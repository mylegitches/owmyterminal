# install.ps1 — adds the ai() function to your PowerShell profile
# Run once: .\install.ps1
# Optional flags:
#   -OllamaUrl   "http://192.168.1.10:11434"   (default: http://localhost:11434)
#   -OllamaModel "mistral"                      (default: llama3.2)

param(
    [string]$OllamaUrl   = "http://localhost:11434",
    [string]$OllamaModel = "llama3.2"
)

$snippet = @"

# ow-my-terminal — AI assistant (https://github.com/mylegitches/owmyterminal)
`$env:OLLAMA_URL   = "$OllamaUrl"
`$env:OLLAMA_MODEL = "$OllamaModel"
. "`$PSScriptRoot\ai.ps1"
"@

$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force $profileDir | Out-Null
}

$aiScript = Join-Path $PSScriptRoot "ai.ps1"

if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Force $PROFILE | Out-Null
}

$existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($existing -match "ow-my-terminal") {
    Write-Host "Already installed in $PROFILE" -ForegroundColor Yellow
    exit 0
}

$snippet.Replace('$PSScriptRoot\ai.ps1', $aiScript) | Add-Content $PROFILE
Write-Host "Installed! Reload your terminal or run: . `$PROFILE" -ForegroundColor Green
Write-Host "Then try: ai 'how do I list open ports'" -ForegroundColor Cyan
