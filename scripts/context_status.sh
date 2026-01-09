#!/bin/bash
# Context Compaction Advisor - Status Line Script
#
# 1. Displays real-time context usage in status bar
# 2. Writes state to ~/.claude/context_state_<session>.json for hook to read
#
# Each session gets its own state file to avoid cross-session contamination.

set -euo pipefail

input=$(cat)

# Extract session ID for session-specific state file
SESSION_ID=$(echo "$input" | jq -r '.session_id // "default"' | tr -d '[:space:]' | cut -c1-16)
STATE_FILE="$HOME/.claude/context_state_${SESSION_ID}.json"

# Parse context window data from Claude Code
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
USAGE=$(echo "$input" | jq -r '.context_window.current_usage // empty')

if [ -z "$USAGE" ] || [ "$USAGE" = "null" ]; then
    echo "[$MODEL] ⏳"
    exit 0
fi

# Calculate total tokens used
INPUT_TOKENS=$(echo "$USAGE" | jq -r '.input_tokens // 0')
CACHE_CREATION=$(echo "$USAGE" | jq -r '.cache_creation_input_tokens // 0')
CACHE_READ=$(echo "$USAGE" | jq -r '.cache_read_input_tokens // 0')
TOTAL_USED=$((INPUT_TOKENS + CACHE_CREATION + CACHE_READ))

# Claude Code reserves ~22.5% as autocompact buffer
BUFFER_PERCENT=23
USABLE_TOKENS=$((CONTEXT_SIZE * (100 - BUFFER_PERCENT) / 100))
FREE_TOKENS=$((USABLE_TOKENS - TOTAL_USED))
if [ $FREE_TOKENS -lt 0 ]; then FREE_TOKENS=0; fi

# Calculate percentage of usable space consumed
if [ $USABLE_TOKENS -gt 0 ]; then
    USED_PERCENT=$((TOTAL_USED * 100 / USABLE_TOKENS))
else
    USED_PERCENT=0
fi
if [ $USED_PERCENT -gt 100 ]; then USED_PERCENT=100; fi

# Progress bar
FILLED=$((USED_PERCENT / 10))
EMPTY=$((10 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

FREE_K=$((FREE_TOKENS / 1000))

# Determine status level
if [ $FREE_TOKENS -lt 15000 ]; then
    STATUS="critical"
    DISPLAY="🔴 COMPACT ${FREE_K}k"
elif [ $FREE_TOKENS -lt 30000 ]; then
    STATUS="warning"
    DISPLAY="🟠 ${FREE_K}k free"
elif [ $FREE_TOKENS -lt 50000 ]; then
    STATUS="caution"
    DISPLAY="🟡 ${FREE_K}k free"
else
    STATUS="safe"
    DISPLAY="🟢 ${FREE_K}k free"
fi

# Read existing tool count (for checkpoint tracking)
TOOL_COUNT=0
LAST_CHECKPOINT=0
if [ -f "$STATE_FILE" ]; then
    TOOL_COUNT=$(jq -r '.tool_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)
    LAST_CHECKPOINT=$(jq -r '.last_checkpoint // 0' "$STATE_FILE" 2>/dev/null || echo 0)
fi

# Write state to session-specific file for hook to read
mkdir -p "$HOME/.claude"
cat > "$STATE_FILE" << EOF
{
  "session_id": "$SESSION_ID",
  "free_tokens": $FREE_TOKENS,
  "free_k": $FREE_K,
  "total_used": $TOTAL_USED,
  "usable_tokens": $USABLE_TOKENS,
  "used_percent": $USED_PERCENT,
  "status": "$STATUS",
  "tool_count": $TOOL_COUNT,
  "last_checkpoint": $LAST_CHECKPOINT,
  "timestamp": $(date +%s)
}
EOF

# Output to status line
echo "[$MODEL] $DISPLAY $BAR"
