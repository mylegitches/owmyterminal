# ow-my-terminal: AI assistant for PowerShell
# Source this file or let install.ps1 add it to your $PROFILE
#
# Config (set in config.ps1 inside this repo):
#   $env:AI_BASE_URL  — API base URL
#                       Ollama local:  http://localhost:11434
#                       MiniMax cloud: https://api.minimaxi.chat
#   $env:AI_MODEL     — model name   (e.g. minimax-m3, llama3.2, mistral)
#   $env:AI_API_KEY   — API key      (leave unset for local Ollama)
#
# Usage:
#   ai "how do I find what process is using port 8080"
#   npm install 2>&1 | ai
#   docker logs myapp 2>&1 | ai "why is this failing"

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
            return
        }

        $baseUrl = if ($env:AI_BASE_URL) { $env:AI_BASE_URL.TrimEnd('/') } else { "http://localhost:11434" }
        $model   = if ($env:AI_MODEL)    { $env:AI_MODEL }    else { "llama3.2" }
        $apiKey  = $env:AI_API_KEY

        $body = [ordered]@{
            model    = $model
            messages = @(
                @{ role = "system"; content = "You are a concise terminal assistant on Windows. Give direct answers and working PowerShell/CMD commands when relevant. Skip preamble." }
                @{ role = "user";   content = $prompt }
            )
            stream   = $true
        } | ConvertTo-Json -Depth 5 -Compress

        try {
            $req = [System.Net.HttpWebRequest]::Create("$baseUrl/v1/chat/completions")
            $req.Method      = "POST"
            $req.ContentType = "application/json"
            $req.Timeout     = 120000

            if ($apiKey) {
                $req.Headers.Add("Authorization", "Bearer $apiKey")
            }

            $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $req.ContentLength = $bytes.Length
            $s = $req.GetRequestStream()
            $s.Write($bytes, 0, $bytes.Length)
            $s.Close()

            $resp   = $req.GetResponse()
            $reader = [System.IO.StreamReader]::new($resp.GetResponseStream())

            Write-Host ""
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if ($line -and $line.StartsWith("data: ")) {
                    $json = $line.Substring(6)
                    if ($json -eq "[DONE]") { break }
                    try {
                        $chunk = $json | ConvertFrom-Json
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
            Write-Host "Could not reach AI at $baseUrl" -ForegroundColor Red
            Write-Host "  Check AI_BASE_URL, AI_MODEL, and AI_API_KEY in config.ps1" -ForegroundColor Yellow
            Write-Host "  Error: $_" -ForegroundColor DarkGray
        }
    }
}
