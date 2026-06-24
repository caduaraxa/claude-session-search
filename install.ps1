# install.ps1 — Install search-sessions skill for Claude Code (Windows)
$dest = "$env:USERPROFILE\.claude\commands"
if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Force $dest | Out-Null
    Write-Host "Created $dest"
}
Copy-Item -Force "$PSScriptRoot\.claude\commands\search-sessions.md" $dest
Write-Host "✅ search-sessions skill installed to $dest"
Write-Host "   Restart VS Code or Claude Code, then use /search-sessions"
