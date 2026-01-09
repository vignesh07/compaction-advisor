#!/bin/bash
# Context Injection Hook - UserPromptSubmit
#
# Reads session-specific context state and outputs warning if concerning.
# Only outputs when context is concerning (caution/warning/critical).

set -euo pipefail

# Read hook input to get session ID
input=$(cat)
SESSION_ID=$(echo "$input" | jq -r '.session_id // "default"' | tr -d '[:space:]' | cut -c1-16)
STATE_FILE="$HOME/.claude/context_state_${SESSION_ID}.json"

# Check if session-specific state file exists
if [ ! -f "$STATE_FILE" ]; then
    # No state file for this session yet - status line hasn't run
    exit 0
fi

# Check file age (must be recent - within 120 seconds)
FILE_TIME=$(stat -f %m "$STATE_FILE" 2>/dev/null || stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
AGE=$((CURRENT_TIME - FILE_TIME))

if [ $AGE -gt 120 ]; then
    # State file is stale, skip
    exit 0
fi

# Read state
STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE")
FREE_K=$(jq -r '.free_k // 0' "$STATE_FILE")

# Only inject context for concerning states
case "$STATUS" in
    critical)
        echo "<context-status>CRITICAL: Only ${FREE_K}k tokens free. Run /compact before any task.</context-status>"
        ;;
    warning)
        echo "<context-status>WARNING: ${FREE_K}k tokens free. Only small tasks safe. Consider /compact before medium+ tasks.</context-status>"
        ;;
    caution)
        echo "<context-status>CAUTION: ${FREE_K}k tokens free. Medium tasks OK, compact before large tasks.</context-status>"
        ;;
    *)
        # Safe - don't inject anything, avoid noise
        exit 0
        ;;
esac
