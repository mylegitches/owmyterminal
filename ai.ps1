# ow-my-terminal: AI assistant for PowerShell
# Source this file or let install.ps1 add it to your $PROFILE
#
# Config (env vars or set defaults below):
#   $env:OLLAMA_URL   — Ollama base URL  (default: http://localhost:11434)
#   $env:OLLAMA_MODEL — model name       (default: llama3.2)
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

        $url   = if ($env:OLLAMA_URL)   { $env:OLLAMA_URL }   else { "http://localhost:11434" }
        $model = if ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { "llama3.2" }

        $body = [ordered]@{
            model    = $model
            messages = @(
                @{ role = "system"; content = "You are a concise terminal assistant on Windows. Give direct answers and working PowerShell/CMD commands when relevant. Skip preamble." }
                @{ role = "user";   content = $prompt }
            )
            stream   = $true
        } | ConvertTo-Json -Depth 5 -Compress

        try {
            $req = [System.Net.HttpWebRequest]::Create("$url/api/chat")
            $req.Method      = "POST"
            $req.ContentType = "application/json"
            $req.Timeout     = 120000

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
                if ($line) {
                    try {
                        $chunk = $line | ConvertFrom-Json
                        if ($chunk.message.content) {
                            Write-Host $chunk.message.content -NoNewline
                        }
                    } catch { }
                }
            }
            Write-Host "`n"
            $reader.Close()
            $resp.Close()
        }
        catch {
            Write-Host "Could not reach Ollama at $url" -ForegroundColor Red
            Write-Host "  Set `$env:OLLAMA_URL to your Ollama host, e.g. http://192.168.1.10:11434" -ForegroundColor Yellow
            Write-Host "  Error: $_" -ForegroundColor DarkGray
        }
    }
}
