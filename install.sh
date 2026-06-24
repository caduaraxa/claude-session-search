#!/usr/bin/env bash
# install.sh — Install search-sessions skill for Claude Code (Mac/Linux)
DEST="$HOME/.claude/commands"
mkdir -p "$DEST"
cp "$(dirname "$0")/.claude/commands/search-sessions.md" "$DEST/"
echo "✅ search-sessions skill installed to $DEST"
echo "   Restart VS Code or Claude Code, then use /search-sessions"
