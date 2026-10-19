# Copy this to config.ps1 and edit to match your setup

# Ollama Cloud (https://ollama.com — get an API key at ollama.com/settings/keys)
$env:AI_BASE_URL = "https://ollama.com"
$env:AI_MODEL    = "minimax-m3"        # any model listed at ollama.com/library
$env:AI_API_KEY  = "your-ollama-api-key"

# Local Ollama (no API key needed)
# $env:AI_BASE_URL = "http://localhost:11434"
# $env:AI_MODEL    = "llama3.2"
# $env:AI_API_KEY  = ""

# Remote Ollama (homelab / NAS)
# $env:AI_BASE_URL = "http://192.168.1.10:11434"
# $env:AI_MODEL    = "mistral"
# $env:AI_API_KEY  = ""
