# Compaction Advisor Diagnostic Test

Run diagnostic checks on the compaction-advisor plugin installation.

## Instructions

Run these checks and report the results:

### 1. Find Plugin Installation
```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/ 2>/dev/null | head -1)
if [ -n "$PLUGIN_DIR" ]; then
  echo "Plugin installed at: $PLUGIN_DIR"
else
  echo "Plugin NOT installed via marketplace"
fi
```

### 2. Session State Files Check
```bash
echo "Session state files:"
ls -la ~/.claude/context_state_*.json 2>/dev/null || echo "  No session state files found"
echo ""
echo "Most recent state file:"
LATEST=$(ls -t ~/.claude/context_state_*.json 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  cat "$LATEST" | jq .
else
  echo "  None - status line hasn't written state yet"
fi
```

### 3. Status Line Configuration
```bash
echo "Status line config in settings.json:"
jq '.statusLine' ~/.claude/settings.json 2>/dev/null || echo "  Not configured"
```

### 4. Hook Configuration
```bash
echo "UserPromptSubmit hooks in settings.json:"
jq '.hooks.UserPromptSubmit' ~/.claude/settings.json 2>/dev/null || echo "  None configured"
```

### 5. Script Permissions
```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/ 2>/dev/null | head -1)
if [ -n "$PLUGIN_DIR" ]; then
  echo "Scripts in $PLUGIN_DIR/scripts/:"
  ls -la "$PLUGIN_DIR/scripts/"
fi
```

## Summary

Report each check with findings and any recommendations.
