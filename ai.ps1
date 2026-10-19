# ow-my-terminal: AI assistant for PowerShell
# Source this file or let install.ps1 add it to your $PROFILE
#
# Config (set in config.ps1 inside this repo):
#   $env:AI_BASE_URL  — API base URL
#                       Ollama Cloud:  https://ollama.com
#                       Ollama local:  http://localhost:11434
#   $env:AI_MODEL     — model name   (e.g. minimax-m3, llama3.2, mistral)
#   $env:AI_API_KEY   — API key      (leave unset for local Ollama)
#
# Usage:
#   ai "how do I find what process is using port 8080"
#   npm install 2>&1 | ai
#   docker logs myapp 2>&1 | ai "why is this failing"
#   aido "install python 3.11"   ← agent mode: executes commands to reach a goal

# ── shared helpers ────────────────────────────────────────────────────────────

function script:Get-AIEndpoint {
    $baseUrl = if ($env:AI_BASE_URL) { $env:AI_BASE_URL.TrimEnd('/') } else { "http://localhost:11434" }
    $endpoint = "$baseUrl/v1/chat/completions"
    $apiKey = $env:AI_API_KEY
    if ($apiKey -and $apiKey -match '^([a-f0-9]{32})\.') {
        $endpoint += "?GroupId=$($Matches[1])"
    }
    return $endpoint
}

function script:New-AIRequest ([string]$endpoint) {
    $req = [System.Net.HttpWebRequest]::Create($endpoint)
    $req.Method      = "POST"
    $req.ContentType = "application/json"
    $req.Timeout     = 120000
    $apiKey = $env:AI_API_KEY
    if ($apiKey) { $req.Headers.Add("Authorization", "Bearer $apiKey") }
    return $req
}

# Non-streaming call — returns full response text (used by aido agent loop)
function script:Invoke-AIChat ([array]$Messages) {
    $model    = if ($env:AI_MODEL) { $env:AI_MODEL } else { "llama3.2" }
    $endpoint = Get-AIEndpoint

    $body = [ordered]@{
        model    = $model
        messages = $Messages
        stream   = $false
    } | ConvertTo-Json -Depth 10 -Compress

    $req   = New-AIRequest $endpoint
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $req.ContentLength = $bytes.Length
    $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()

    $resp    = $req.GetResponse()
    $reader  = [System.IO.StreamReader]::new($resp.GetResponseStream())
    $json    = $reader.ReadToEnd()
    $reader.Close(); $resp.Close()

    return ($json | ConvertFrom-Json).choices[0].message.content
}

# ── ai: ask a question or explain piped output ─────────────────────────────

function ai {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Question = "",

        [Parameter(ValueFromPipeline=$true)]
        [string]$PipedInput
    )

    begin {
        $pipedLines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($PipedInput) { $pipedLines.Add($PipedInput) }
    }

    end {
        $context = $pipedLines -join "`n"

        if ($context -and $Question) {
            $prompt = "$Question`n`nOutput/context:`n$context"
        } elseif ($context) {
            $prompt = "Explain this output or error and suggest a fix if needed:`n`n$context"
        } else {
            $prompt = $Question
        }

        if (-not $prompt.Trim()) {
            Write-Host "Usage:" -ForegroundColor Cyan
            Write-Host "  ai 'how do I list open ports'"
            Write-Host "  npm install 2>&1 | ai"
            Write-Host "  npm install 2>&1 | ai 'why is this failing'"
            Write-Host "  aido 'install python 3.11'   # agent mode"
            return
        }

        $model    = if ($env:AI_MODEL) { $env:AI_MODEL } else { "llama3.2" }
        $endpoint = Get-AIEndpoint

        $body = [ordered]@{
            model    = $model
            messages = @(
                @{ role = "system"; content = "You are a concise terminal assistant on Windows. Give direct answers and working PowerShell/CMD commands when relevant. Skip preamble." }
                @{ role = "user";   content = $prompt }
            )
            stream   = $true
        } | ConvertTo-Json -Depth 5 -Compress

        try {
            $req   = New-AIRequest $endpoint
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $req.ContentLength = $bytes.Length
            $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()

            $resp   = $req.GetResponse()
            $reader = [System.IO.StreamReader]::new($resp.GetResponseStream())

            Write-Host ""
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if ($line -and $line.StartsWith("data: ")) {
                    $json = $line.Substring(6)
                    if ($json -eq "[DONE]") { break }
                    try {
                        $chunk   = $json | ConvertFrom-Json
                        $content = $chunk.choices[0].delta.content
                        if ($content) { Write-Host $content -NoNewline }
                    } catch { }
                }
            }
            Write-Host "`n"
            $reader.Close()
            $resp.Close()
        }
        catch {
            Write-Host "Could not reach AI at $($env:AI_BASE_URL)" -ForegroundColor Red
            Write-Host "  Check AI_BASE_URL, AI_MODEL, and AI_API_KEY in config.ps1" -ForegroundColor Yellow
            Write-Host "  Error: $_" -ForegroundColor DarkGray
        }
    }
}

# ── aido: agent mode — AI proposes commands, you confirm, it loops ────────────

function aido {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Goal,

        [switch]$Yes   # -Yes to auto-confirm every command (use carefully)
    )

    $systemPrompt = @"
You are an autonomous Windows terminal agent. The user gives you a goal and you achieve it step by step.

Rules:
- Explain briefly what you are about to do (1-2 sentences max)
- Output EXACTLY ONE command to run, in a fenced code block tagged powershell or cmd
- After seeing the command output, decide whether the goal is achieved or more steps are needed
- When the goal is fully achieved, respond with DONE: followed by a one-line summary and NO code block
- Prefer winget for software installs. Use PowerShell syntax unless cmd is clearly better.
- Never chain destructive commands. One command per step.
"@

    $messages = [System.Collections.Generic.List[hashtable]]::new()
    $messages.Add(@{ role = "system"; content = $systemPrompt })
    $messages.Add(@{ role = "user";   content = "Goal: $Goal" })

    Write-Host ""
    Write-Host "Goal: $Goal" -ForegroundColor Cyan
    Write-Host ("-" * 50) -ForegroundColor DarkGray

    $maxSteps = 15
    for ($step = 1; $step -le $maxSteps; $step++) {

        Write-Host ""
        Write-Host "Thinking..." -ForegroundColor DarkGray

        try {
            $response = Invoke-AIChat -Messages $messages.ToArray()
        } catch {
            Write-Host "AI error: $_" -ForegroundColor Red
            break
        }

        # Done?
        if ($response -match '(?m)^DONE:') {
            Write-Host ""
            Write-Host $response -ForegroundColor Green
            break
        }

        # Extract command from code block
        if ($response -match '(?s)```(?:powershell|cmd|batch|shell|sh|bash)?\s*\r?\n(.*?)\r?\n```') {
            $command  = $Matches[1].Trim()
            $explain  = $response -replace '(?s)```.*?```', '' | ForEach-Object { $_.Trim() }

            Write-Host ""
            if ($explain) { Write-Host $explain -ForegroundColor White }
            Write-Host ""
            Write-Host "  > $command" -ForegroundColor Yellow

            $run = $Yes
            if (-not $run) {
                $ans = Read-Host "  Run this? [Y/n]"
                $run = ($ans -eq '' -or $ans -match '^[Yy]')
            }

            if ($run) {
                Write-Host ""
                $output = Invoke-Expression $command 2>&1 | Out-String
                Write-Host $output.TrimEnd()

                $messages.Add(@{ role = "assistant"; content = $response })
                $messages.Add(@{ role = "user";      content = "Command output:`n$($output.Trim())`n`nContinue toward the goal, or say DONE: if it is achieved." })
            } else {
                Write-Host "  Skipped. Stopping." -ForegroundColor DarkGray
                break
            }
        } else {
            # AI responded without a command — show it and ask what to do
            Write-Host ""
            Write-Host $response -ForegroundColor White
            $messages.Add(@{ role = "assistant"; content = $response })
            $messages.Add(@{ role = "user";      content = "Please provide the next command to run, or say DONE: if the goal is achieved." })
        }
    }
}
