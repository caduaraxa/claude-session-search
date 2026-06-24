# search-sessions — Search Claude Code sessions by date and/or content

Searches all `.jsonl` session files under `~/.claude/projects/`, filtering by date and/or keyword. After showing results, offers to load a session's full conversation so you can ask questions, request summaries, compare with current code, etc.

## Usage

```
/search-sessions [date] [keyword]
/search-sessions 2026-06-18
/search-sessions watcher
/search-sessions 2026-06-18 watcher
/search-sessions "proximity alert"
/search-sessions
```

- **date**: `YYYY-MM-DD` or partial (`2026-06`, `06-18`). Optional.
- **keyword**: any text to search in message content. Optional.
- No arguments: lists all sessions with title and date range.

## Arguments

`$ARGUMENTS`

---

## Instructions

### 1. Check for arguments — ask if missing

If `$ARGUMENTS` is empty or blank, **do not run the search yet**. Instead, ask the user:

> No filter provided. What are you looking for?
> - **Date** (e.g. `2026-06-18`, `2026-06`, `06-18`)
> - **Keyword or topic** (e.g. `watcher`, `proximity alert`, `auth`)
> - **Both** — or type `all` to list every session

Wait for the user's reply and treat it as the new `$ARGUMENTS` before continuing.

### 2. Parse arguments

From `$ARGUMENTS`, identify:
- **date filter**: any token that looks like a date (contains `-` and digits, e.g. `2026-06-18`, `06-18`, `2026-06`)
- **keyword filter**: the rest of the text (may be empty)

### 2. Detect OS and run the search

**Detect the operating system** and run the appropriate script.

---

#### Windows (PowerShell)

Replace `DATE_FILTER` and `KEYWORD_FILTER` with the extracted values (empty string `""` if none):

```powershell
$projectsRoot = "$env:USERPROFILE\.claude\projects"
$dateFilter   = "DATE_FILTER"
$keyword      = "KEYWORD_FILTER"
$idx          = 0
$results      = @()

Get-ChildItem $projectsRoot -Recurse -Filter "*.jsonl" | ForEach-Object {
    $file = $_
    $projectName = $file.DirectoryName | Split-Path -Leaf
    $lines = Get-Content $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines) { return }

    $aiTitle = ""
    $lines | ForEach-Object {
        try {
            $d = $_ | ConvertFrom-Json
            if ($d.type -eq "ai-title" -and $d.aiTitle) { $aiTitle = $d.aiTitle }
        } catch {}
    }

    $dates = $lines | ForEach-Object {
        try { ($_ | ConvertFrom-Json).timestamp.Substring(0,10) } catch {}
    } | Where-Object { $_ } | Sort-Object -Unique
    if (-not $dates) { return }
    $dateRange = "$($dates[0]) → $($dates[-1])"

    if ($dateFilter -ne "") {
        $matchDate = $dates | Where-Object { $_ -like "*$dateFilter*" }
        if (-not $matchDate) { return }
    }

    $matchExcerpt = ""
    if ($keyword -ne "") {
        $found = $false
        foreach ($line in $lines) {
            try {
                $d = $line | ConvertFrom-Json
                $content = $d.message.content
                $text = if ($content -is [string]) { $content } `
                        else { ($content | Where-Object { $_.type -eq "text" } | Select-Object -First 1).text }
                if ($text -and $text -match [regex]::Escape($keyword)) {
                    $i = $text.IndexOf($keyword, [System.StringComparison]::OrdinalIgnoreCase)
                    $s = [Math]::Max(0, $i - 40)
                    $l = [Math]::Min(120, $text.Length - $s)
                    $matchExcerpt = "..." + $text.Substring($s, $l).Trim() + "..."
                    $found = $true
                    break
                }
            } catch {}
        }
        if (-not $found) { return }
    }

    $idx++
    $results += [PSCustomObject]@{
        Index   = $idx
        Title   = if ($aiTitle) { $aiTitle } else { "(no title)" }
        Dates   = $dateRange
        Project = $projectName
        File    = $file.FullName
        Excerpt = $matchExcerpt
    }
}

$results | Sort-Object Dates -Descending | ForEach-Object {
    Write-Host "$($_.Index). 📁 $($_.Project)"
    Write-Host "   🏷  $($_.Title)"
    Write-Host "   📅  $($_.Dates)"
    Write-Host "   🔑  $($_.File)"
    if ($_.Excerpt) { Write-Host "   💬  $($_.Excerpt)" }
    Write-Host ""
}
Write-Host "Total: $($results.Count) session(s) found."
```

---

#### Mac / Linux (bash)

```bash
PROJECTS_ROOT="$HOME/.claude/projects"
DATE_FILTER="DATE_FILTER"
KEYWORD="KEYWORD_FILTER"
idx=0

find "$PROJECTS_ROOT" -name "*.jsonl" | while read -r file; do
    project=$(basename "$(dirname "$file")")

    ai_title=$(grep -o '"ai-title"' "$file" | head -1)
    if [ -n "$ai_title" ]; then
        ai_title=$(grep '"aiTitle"' "$file" | tail -1 | sed 's/.*"aiTitle":"\([^"]*\)".*/\1/')
    fi
    [ -z "$ai_title" ] && ai_title="(no title)"

    dates=$(grep -o '"timestamp":"[0-9-]*' "$file" | sed 's/"timestamp":"//' | cut -c1-10 | sort -u)
    [ -z "$dates" ] && continue
    first=$(echo "$dates" | head -1)
    last=$(echo "$dates" | tail -1)

    if [ -n "$DATE_FILTER" ]; then
        echo "$dates" | grep -q "$DATE_FILTER" || continue
    fi

    excerpt=""
    if [ -n "$KEYWORD" ]; then
        match=$(grep -i "$KEYWORD" "$file" | head -1)
        [ -z "$match" ] && continue
        excerpt=$(echo "$match" | grep -o ".\{0,60\}$KEYWORD.\{0,60\}" | head -1)
        excerpt="...$excerpt..."
    fi

    idx=$((idx + 1))
    echo "$idx. 📁 $project"
    echo "   🏷  $ai_title"
    echo "   📅  $first → $last"
    echo "   🔑  $file"
    [ -n "$excerpt" ] && echo "   💬  $excerpt"
    echo ""
done
```

---

### 3. Show results

Display results numbered for easy reference. If no results, say so clearly and suggest adjusting the filter.

### 4. Offer to load a session

After listing results, **always** ask:

> Want to load the content of a session? Enter its number or UUID.

If the user provides a number or UUID, identify the full path to the `.jsonl` file and run the loader below.

---

#### Load session — Windows (PowerShell)

Replace `SESSION_PATH` with the full path:

```powershell
$path = "SESSION_PATH"
$lines = Get-Content $path -Encoding UTF8
$turns = @()
foreach ($line in $lines) {
    try {
        $d = $line | ConvertFrom-Json
        $role = $d.message.role
        if ($role -notin @("user","assistant")) { continue }
        $content = $d.message.content
        $text = if ($content -is [string]) { $content }
                else { ($content | Where-Object { $_.type -eq "text" } | Select-Object -First 1).text }
        if (-not $text -or $text.Trim().Length -lt 5) { continue }
        $clean = $text.Trim()
        if ($clean -match "^<ide_" -and $clean.Length -lt 200) { continue }
        $turns += [PSCustomObject]@{
            ts   = $d.timestamp.Substring(0,19)
            role = $role.ToUpper()
            text = $clean.Substring(0, [Math]::Min(500, $clean.Length))
        }
    } catch {}
}
Write-Host "Turns loaded: $($turns.Count)"
$turns | ForEach-Object {
    Write-Host ""
    Write-Host "[$($_.ts)] $($_.role):"
    Write-Host $_.text
    Write-Host "---"
}
```

#### Load session — Mac / Linux (bash)

```bash
FILE="SESSION_PATH"
python3 - <<'EOF'
import json, sys
path = sys.argv[1]
turns = []
with open(path, encoding='utf-8') as f:
    for line in f:
        try:
            d = json.loads(line)
            role = d.get('message', {}).get('role', '')
            if role not in ('user', 'assistant'):
                continue
            content = d['message']['content']
            if isinstance(content, str):
                text = content
            else:
                text = next((b['text'] for b in content if b.get('type') == 'text'), '')
            text = text.strip()
            if len(text) < 5:
                continue
            if text.startswith('<ide_') and len(text) < 200:
                continue
            ts = d.get('timestamp', '')[:19]
            print(f"\n[{ts}] {role.upper()}:")
            print(text[:500])
            print("---")
            turns.append(text)
        except Exception:
            pass
print(f"\nTurns loaded: {len(turns)}")
EOF
```

---

### 5. After loading

Confirm to the user:

> Session **"<aiTitle>"** loaded — **N turns** available (<start date> → <end date>).  
> You can now ask questions, request a summary, search for decisions, compare with current code, etc.

From this point, answer the user's questions based on the loaded session content.
