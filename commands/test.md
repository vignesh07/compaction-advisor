# Compaction Advisor Diagnostic Test

Run diagnostic checks on the compaction-advisor plugin installation.

## Instructions

Run these checks and report the results:

### 1. State File Check
```bash
if [ -f ~/.claude/context_state.json ]; then
  echo "✓ State file exists"
  AGE=$(($(date +%s) - $(stat -f %m ~/.claude/context_state.json 2>/dev/null || stat -c %Y ~/.claude/context_state.json)))
  echo "  Age: ${AGE}s"
  if [ $AGE -lt 60 ]; then
    echo "  ✓ Fresh (status line is running)"
  else
    echo "  ⚠ Stale (status line may not be configured)"
  fi
  echo "  Contents:"
  cat ~/.claude/context_state.json | jq -r '"  free_k: \(.free_k)k, status: \(.status)"'
else
  echo "✗ State file missing - status line not running"
fi
```

### 2. Hook Script Check
```bash
SCRIPT="$HOME/.claude/plugins/cache/compaction-advisor/compaction-advisor/1.0.0/scripts/inject_context.sh"
if [ -f "$SCRIPT" ]; then
  echo "✓ Hook script exists"
  if [ -x "$SCRIPT" ]; then
    echo "  ✓ Executable"
  else
    echo "  ✗ Not executable - run: chmod +x \"$SCRIPT\""
  fi
else
  echo "✗ Hook script missing at expected path"
fi
```

### 3. Status Line Script Check
```bash
SCRIPT="$HOME/.claude/plugins/cache/compaction-advisor/compaction-advisor/1.0.0/scripts/context_status.sh"
if [ -f "$SCRIPT" ]; then
  echo "✓ Status line script exists"
  if [ -x "$SCRIPT" ]; then
    echo "  ✓ Executable"
  else
    echo "  ✗ Not executable"
  fi
else
  echo "✗ Status line script missing"
fi
```

### 4. Settings Check
```bash
if grep -q "context_status.sh" ~/.claude/settings.json 2>/dev/null; then
  echo "✓ Status line configured in settings.json"
else
  echo "✗ Status line NOT configured in settings.json"
  echo "  Add to ~/.claude/settings.json:"
  echo '  "statusLine": {"type": "command", "command": "~/.claude/plugins/cache/compaction-advisor/compaction-advisor/1.0.0/scripts/context_status.sh"}'
fi
```

### 5. Hook Injection Test
```bash
echo "Current hook output:"
~/.claude/plugins/cache/compaction-advisor/compaction-advisor/1.0.0/scripts/inject_context.sh 2>&1 || echo "(no output - context is healthy or state file issue)"
```

## Summary

Report each check as ✓ (pass) or ✗ (fail) with recommendations for any failures.
