# OwMyTerminal

AI assistant for your terminal — PowerShell, Command Prompt, or any shell. Ask questions and pipe command output directly — no copy-pasting to a chatbot.

```powershell
# Ask anything
ai "how do I find what process is using port 8080"

# Pipe errors straight to AI
npm install 2>&1 | ai

# Pipe output with a specific question
docker logs myapp 2>&1 | ai "why is this failing"
```

Works in **PowerShell** and **cmd.exe** out of the box.

Two modes:
- **`ai`** — ask a question or pipe output for explanation
- **`aido`** — give it a goal and it executes commands step by step to get there

## Install

**1. Get a model**

Option A — [Ollama Cloud](https://ollama.com) (cloud-hosted, API key required):
- Sign up at [ollama.com](https://ollama.com) and get an API key from your account settings
- Base URL: `https://ollama.com`, pick any model from [ollama.com/library](https://ollama.com/library)

Option B — Local Ollama (no API key needed):
```
winget install Ollama.Ollama
ollama pull llama3.2
```

**2. Clone and install**

```powershell
git clone https://github.com/mylegitches/owmyterminal
cd owmyterminal
.\install.ps1
```

The installer:
- Writes your config to `config.ps1` inside the repo
- Adds the repo folder to your user PATH (so `ai` works in cmd too)
- Adds a loader line to your PowerShell `$PROFILE`

**3. Add your API key to `config.ps1`** (cloud only)

```powershell
# owmyterminal/config.ps1
$env:AI_API_KEY = "your-api-key-here"
```

**4. Reload PowerShell** (cmd picks up PATH automatically on next open)

```powershell
. $PROFILE
```

## Usage

### `ai` — ask / explain

```powershell
ai "how do I list open ports"
netstat -ano | ai "what's using the most connections"
npm install 2>&1 | ai "why is this failing"
```

Same syntax in cmd.exe:

```cmd
ai "how do I list open ports"
netstat -ano 2>&1 | ai "what's using the most connections"
```

### `aido` — agent mode

Give it a goal. It proposes one command at a time, shows you what it wants to run, and asks before executing. Loops until the goal is done.

```powershell
aido "install python 3.11"
aido "find and kill whatever is using port 8080"
aido "create a venv and install requests"
```

Add `-Yes` to skip confirmation prompts (use carefully):

```powershell
aido "update all winget packages" -Yes
```

## Configuration

Config lives in `config.ps1` inside the repo — edit it any time, no reinstall needed:

```powershell
# owmyterminal/config.ps1

# Ollama Cloud
$env:AI_BASE_URL = "https://ollama.com"
$env:AI_MODEL    = "llama3.2"          # any model at ollama.com/library
$env:AI_API_KEY  = "your-api-key"

# Local Ollama (no key needed)
# $env:AI_BASE_URL = "http://localhost:11434"
# $env:AI_MODEL    = "llama3.2"
# $env:AI_API_KEY  = ""

# Remote Ollama (homelab / NAS)
# $env:AI_BASE_URL = "http://192.168.1.10:11434"
# $env:AI_MODEL    = "mistral"
# $env:AI_API_KEY  = ""
```

`config.ps1` is git-ignored so your API key never gets committed. See `config.example.ps1` for all options.

## Manual install (no installer)

Add to your PowerShell `$PROFILE`:

```powershell
. "C:\path\to\owmyterminal\config.ps1"
. "C:\path\to\owmyterminal\ai.ps1"
```

For cmd support, add the `owmyterminal` folder to your user PATH.

## Requirements

- Windows (PowerShell 5.1+ or cmd.exe)
- [Ollama](https://ollama.com) locally, on your network, or via cloud API
