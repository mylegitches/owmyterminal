# install.ps1 — adds the ai() function to your PowerShell profile
#               and adds the repo to PATH so ai.bat works in cmd too
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

$repoDir    = $PSScriptRoot
$configFile = Join-Path $repoDir "config.ps1"
$aiFile     = Join-Path $repoDir "ai.ps1"

# Write config into the repo
@"
# ow-my-terminal config — edit this file, not your `$PROFILE
`$env:AI_BASE_URL = "$OllamaUrl"
`$env:AI_MODEL    = "$OllamaModel"
`$env:AI_API_KEY  = ""   # paste your API key here if using a cloud model
"@ | Set-Content $configFile -Encoding UTF8

# Add repo dir to user PATH so ai.bat works in cmd and any shell
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$repoDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$repoDir", "User")
    Write-Host "Added to PATH: $repoDir" -ForegroundColor Green
    Write-Host "  Restart any open cmd/terminal windows to pick up the PATH change." -ForegroundColor Yellow
} else {
    Write-Host "PATH already contains repo dir." -ForegroundColor Green
}

# Add loader line to PowerShell $PROFILE
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force $profileDir | Out-Null
}
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Force $PROFILE | Out-Null
}

$existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($existing -match "ow-my-terminal") {
    Write-Host "PowerShell profile entry already exists." -ForegroundColor Green
} else {
    @"

# ow-my-terminal (https://github.com/mylegitches/owmyterminal)
. "$configFile"
. "$aiFile"
"@ | Add-Content $PROFILE -Encoding UTF8
    Write-Host "Added to PowerShell profile: $PROFILE" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Usage:" -ForegroundColor Cyan
Write-Host "  PowerShell:  ai 'question'  or  command | ai"
Write-Host "  cmd:         ai 'question'  or  command 2>&1 | ai"
Write-Host "  Config:      $configFile"
