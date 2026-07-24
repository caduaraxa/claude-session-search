# claude-session-search
![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)
![GNU Bash](https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=GNU%20Bash&logoColor=white)

A [Claude Code](https://claude.ai/code) slash command (`/search-sessions`) that lets you search your local conversation history by **date**, **keyword**, or both — and load any session's full content to ask questions, get summaries, or compare decisions with your current code.

## Why

If you use Claude agents in VS Code or via the Desktop/CLI app and find yourself creating dozens of sessions — only to forget which one covered a specific topic, decision, or the exact day you worked on something — this skill is for you.

Claude Code stores every conversation locally as `.jsonl` files under `~/.claude/projects/`, but provides no built-in way to search them. This skill makes that archive fully searchable and interactive without leaving your editor. You can filter by date, keywords, topics, commit IDs, error messages, or any text that appeared in a conversation.

## Install

**Windows (PowerShell):**
```powershell
.\install.ps1
```

**Mac / Linux:**
```bash
chmod +x install.sh && ./install.sh
```

This copies `search-sessions.md` to `~/.claude/commands/`. Restart VS Code or Claude Code to pick it up.

## Usage

```
/search-sessions                        # asks what you're looking for
/search-sessions all                    # list all sessions
/search-sessions 2026-06-18             # sessions from a specific date
/search-sessions watcher                # sessions mentioning "watcher"
/search-sessions 2026-06-18 watcher     # combine date + keyword
/search-sessions "proximity alert"      # multi-word keyword
```

## What it does

1. **Searches** all `.jsonl` files in `~/.claude/projects/` across every project
2. **Filters** by date (full or partial: `2026-06`, `06-18`) and/or keyword in message content
3. **Shows** results numbered with AI-generated title, date range, project name, and a matching excerpt
4. **Asks** if you want to load a session — enter the number or UUID
5. **Loads** the conversation turns so you can ask follow-up questions, request summaries, extract decisions, compare with current code, etc.

## Example output

```
1. 📁 ProjectNode
   🏷  Add loading spinner after login
   📅  2026-06-18 → 2026-06-18
   🔑  3b5e7fae-1d76-4765-bb74-0bde6ea34c38.jsonl
   💬  ...restart watcher after removing broadcast...

Total: 1 session(s) found.

Want to load the content of a session? Enter its number or UUID.
```

## Requirements

- [Claude Code](https://claude.ai/code) (VS Code extension or CLI)
- Windows: PowerShell 5.1+
- Mac/Linux: bash + Python 3

## How session titles work

Claude Code automatically generates an `ai-title` for each session based on the first meaningful message. This skill reads that title from the `.jsonl` file — no manual tagging needed.

## Author

Created by [caduaraxa](https://github.com/caduaraxa).

## Contributing

PRs welcome. Ideas:
- Export a session as Markdown
- Cross-project deduplication
- Date range filter (`from` / `to`)
