# OwMyTerminal

AI assistant for PowerShell, powered by [Ollama](https://ollama.com). Ask questions and pipe command output directly — no copy-pasting to a chatbot.

```powershell
# Ask anything
ai "how do I find what process is using port 8080"

# Pipe errors straight to AI
npm install 2>&1 | ai

# Pipe output with a specific question
docker logs myapp 2>&1 | ai "why is this failing"
```

## Install

**1. Install and start Ollama**

Download from [ollama.com](https://ollama.com) and pull a model:

```powershell
ollama pull llama3.2
```

**2. Run the installer**

```powershell
git clone https://github.com/mylegitches/owmyterminal
cd owmyterminal
.\install.ps1
```

Point at a remote Ollama host (homelab, NAS, etc.):

```powershell
.\install.ps1 -OllamaUrl "http://192.168.1.10:11434" -OllamaModel "mistral"
```

**3. Reload your terminal**

```powershell
. $PROFILE
```

## Switch hosts on the fly

```powershell
# Use homelab Ollama
$env:OLLAMA_URL = "http://192.168.1.10:11434"

# Switch back to local
$env:OLLAMA_URL = "http://localhost:11434"

# Change model
$env:OLLAMA_MODEL = "mistral"
```

## Manual install (no installer)

Add to your `$PROFILE`:

```powershell
$env:OLLAMA_URL   = "http://localhost:11434"
$env:OLLAMA_MODEL = "llama3.2"
. "C:\path\to\owmyterminal\ai.ps1"
```

## Requirements

- PowerShell 5.1 or later
- [Ollama](https://ollama.com) running locally or on your network
