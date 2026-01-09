#!/bin/bash
# Checkpoint Advisor - PostToolUse Hook
#
# Monitors tool usage during long tasks and suggests checkpoints
# when context is getting low. Prevents mid-task compaction surprise.
#
# Only triggers when:
# 1. Context is concerning (warning/critical)
# 2. Multiple tools have been called since last checkpoint (8+)

set -euo pipefail

# Read hook input to get session ID
input=$(cat)
SESSION_ID=$(echo "$input" | jq -r '.session_id // "default"' | tr -d '[:space:]' | cut -c1-16)
TOOL_NAME=$(echo "$input" | jq -r '.tool_name // "unknown"')
STATE_FILE="$HOME/.claude/context_state_${SESSION_ID}.json"

# Only track modifying tools (skip reads, searches)
case "$TOOL_NAME" in
    Edit|Write|Bash|NotebookEdit)
        # These are significant operations worth tracking
        ;;
    *)
        # Skip tracking for read-only tools
        exit 0
        ;;
esac

# Check if state file exists
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Read current state
STATUS=$(jq -r '.status // "safe"' "$STATE_FILE")
FREE_K=$(jq -r '.free_k // 0' "$STATE_FILE")
TOOL_COUNT=$(jq -r '.tool_count // 0' "$STATE_FILE")
LAST_CHECKPOINT=$(jq -r '.last_checkpoint // 0' "$STATE_FILE")

# Increment tool count
NEW_TOOL_COUNT=$((TOOL_COUNT + 1))
TOOLS_SINCE_CHECKPOINT=$((NEW_TOOL_COUNT - LAST_CHECKPOINT))

# Update state file with new tool count
jq --argjson tc "$NEW_TOOL_COUNT" '.tool_count = $tc' "$STATE_FILE" > "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"

# Checkpoint thresholds
MIN_TOOLS_FOR_CHECKPOINT=8  # Don't warn until 8+ operations
CHECKPOINT_INTERVAL=10      # After checkpoint, wait another 10 operations

# Only suggest checkpoint if:
# 1. Context is concerning (not safe)
# 2. Enough operations since last checkpoint
if [ "$STATUS" != "safe" ] && [ $TOOLS_SINCE_CHECKPOINT -ge $MIN_TOOLS_FOR_CHECKPOINT ]; then

    # Update last checkpoint marker
    jq --argjson lc "$NEW_TOOL_COUNT" '.last_checkpoint = $lc' "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    # Output checkpoint suggestion (goes to Claude's context)
    case "$STATUS" in
        critical)
            echo "<context-checkpoint>"
            echo "CHECKPOINT RECOMMENDED: Context critically low (${FREE_K}k free) after ${TOOLS_SINCE_CHECKPOINT} operations."
            echo "Good time to pause and /compact. Summarize progress so far and key context to preserve."
            echo "</context-checkpoint>"
            ;;
        warning)
            echo "<context-checkpoint>"
            echo "CHECKPOINT SUGGESTED: Context at ${FREE_K}k free after ${TOOLS_SINCE_CHECKPOINT} operations."
            echo "If more significant work remains, consider /compact now to avoid mid-task interruption."
            echo "</context-checkpoint>"
            ;;
        caution)
            # Only warn on caution if many operations
            if [ $TOOLS_SINCE_CHECKPOINT -ge 15 ]; then
                echo "<context-checkpoint>"
                echo "Context update: ${FREE_K}k free after ${TOOLS_SINCE_CHECKPOINT} operations. Still OK for medium tasks."
                echo "</context-checkpoint>"
            fi
            ;;
    esac
fi
