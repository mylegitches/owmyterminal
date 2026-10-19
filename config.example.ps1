# Copy this to config.ps1 and edit to match your setup

# MiniMax cloud
$env:AI_BASE_URL = "https://api.minimaxi.chat"
$env:AI_MODEL    = "minimax-m3"
$env:AI_API_KEY  = "your-minimax-api-key"

# Local Ollama (no API key needed)
# $env:AI_BASE_URL = "http://localhost:11434"
# $env:AI_MODEL    = "llama3.2"
# $env:AI_API_KEY  = ""

# Remote Ollama (homelab / NAS)
# $env:AI_BASE_URL = "http://192.168.1.10:11434"
# $env:AI_MODEL    = "mistral"
# $env:AI_API_KEY  = ""
