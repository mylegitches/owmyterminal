# install.ps1 — adds the ai() function to your PowerShell profile
# Run once: .\install.ps1
# Optional flags:
#   -OllamaUrl   "http://192.168.1.10:11434"   (default: http://localhost:11434)
#   -OllamaModel "mistral"                      (default: llama3.2)
#
# Config lives in config.ps1 inside this repo — edit it any time.

param(
    [string]$OllamaUrl   = "http://localhost:11434",
    [string]$OllamaModel = "llama3.2"
)

$repoDir   = $PSScriptRoot
$configFile = Join-Path $repoDir "config.ps1"
$aiFile     = Join-Path $repoDir "ai.ps1"

# Write config into the repo
@"
# ow-my-terminal config — edit this file, not your `$PROFILE
`$env:OLLAMA_URL   = "$OllamaUrl"
`$env:OLLAMA_MODEL = "$OllamaModel"
"@ | Set-Content $configFile -Encoding UTF8

# Add a single loader line to $PROFILE
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force $profileDir | Out-Null
}
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Force $PROFILE | Out-Null
}

$existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($existing -match "ow-my-terminal") {
    Write-Host "Profile entry already exists — config.ps1 updated." -ForegroundColor Green
    exit 0
}

@"

# ow-my-terminal (https://github.com/mylegitches/owmyterminal)
. "$configFile"
. "$aiFile"
"@ | Add-Content $PROFILE -Encoding UTF8

Write-Host "Installed! Reload your terminal or run: . `$PROFILE" -ForegroundColor Green
Write-Host "Config lives at: $configFile" -ForegroundColor Cyan
Write-Host "Then try: ai 'how do I list open ports'" -ForegroundColor Cyan
