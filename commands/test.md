# Compaction Advisor Diagnostic Test

Run these diagnostic checks and report results:

## 1. Plugin Installation
Run: `ls ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/`

## 2. Session State Files
Run: `ls -la ~/.claude/context_state_*.json`

If no files found, the status line hasn't written state yet.

## 3. Status Line Config
Run: `jq '.statusLine' ~/.claude/settings.json`

## 4. Hook Config
Run: `jq '.hooks.UserPromptSubmit' ~/.claude/settings.json`

## 5. Latest State File Content
Run: `cat ~/.claude/context_state_*.json | head -20`

## Summary
Report what's working and what needs fixing.
