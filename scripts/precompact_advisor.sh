#!/bin/bash
# PreCompact Advisor - Emergency Context Save
#
# Fires just before auto-compaction triggers.
# Gives Claude a last chance to note what to preserve.

set -euo pipefail

# Read hook input to get session ID
input=$(cat)
SESSION_ID=$(echo "$input" | jq -r '.session_id // "default"' | tr -d '[:space:]' | cut -c1-16)
STATE_FILE="$HOME/.claude/context_state_${SESSION_ID}.json"

# Read state if available
TOOL_COUNT=0
if [ -f "$STATE_FILE" ]; then
    TOOL_COUNT=$(jq -r '.tool_count // 0' "$STATE_FILE")
fi

# Output emergency message
echo "<precompact-warning>"
echo "AUTO-COMPACTION IMMINENT"
echo ""
echo "Context window is full. Compaction will happen after this message."
echo "Operations this session: $TOOL_COUNT"
echo ""
echo "IMPORTANT: In your next response after compaction, remember to:"
echo "1. Briefly summarize what you were working on"
echo "2. Note any important decisions or context"
echo "3. Check the current state of files before continuing"
echo "</precompact-warning>"
