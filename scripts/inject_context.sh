#!/bin/bash
# Context Injection Hook - UserPromptSubmit
#
# Reads context state written by status line script and outputs it
# so Claude automatically knows the current context situation.
#
# Only outputs when context is concerning (caution/warning/critical)
# to avoid noise on every prompt.

set -euo pipefail

STATE_FILE="$HOME/.claude/context_state.json"

# Check if state file exists and is recent (within last 60 seconds)
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Check file age
FILE_TIME=$(stat -f %m "$STATE_FILE" 2>/dev/null || stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
AGE=$((CURRENT_TIME - FILE_TIME))

if [ $AGE -gt 60 ]; then
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
