#!/bin/bash
# Compaction Advisor - Auto Setup Script
#
# Automatically configures the status line in ~/.claude/settings.json
# Run this once after plugin installation.

set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

# Find the plugin installation path
PLUGIN_ROOT=""

# Check common plugin cache locations
for path in "$HOME/.claude/plugins/cache/compaction-advisor/compaction-advisor"/*; do
    if [ -d "$path/scripts" ] && [ -f "$path/scripts/context_status.sh" ]; then
        PLUGIN_ROOT="$path"
        break
    fi
done

# Fallback: check if running from repo clone
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$PLUGIN_ROOT" ] && [ -f "$SCRIPT_DIR/context_status.sh" ]; then
    PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
fi

if [ -z "$PLUGIN_ROOT" ]; then
    echo "ERROR: Could not find compaction-advisor installation."
    echo "Please install the plugin first:"
    echo "  /plugin marketplace add vignesh07/compaction-advisor"
    echo "  /plugin install compaction-advisor"
    exit 1
fi

STATUS_SCRIPT="$PLUGIN_ROOT/scripts/context_status.sh"

if [ ! -f "$STATUS_SCRIPT" ]; then
    echo "ERROR: Status script not found at: $STATUS_SCRIPT"
    exit 1
fi

echo "Found compaction-advisor at: $PLUGIN_ROOT"

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS_FILE" ]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo '{}' > "$SETTINGS_FILE"
fi

# Read current settings and add statusLine
if command -v jq &> /dev/null; then
    # Use jq for proper JSON manipulation
    TEMP_FILE=$(mktemp)
    jq --arg cmd "$STATUS_SCRIPT" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SETTINGS_FILE"
    echo "SUCCESS: Status line configured!"
    echo ""
    echo "Added to $SETTINGS_FILE:"
    echo "  statusLine.command = $STATUS_SCRIPT"
    echo ""
    echo ">>> Restart Claude Code for the status line to appear <<<"
else
    echo "ERROR: jq is required but not installed."
    echo ""
    echo "Install jq:"
    echo "  brew install jq      (macOS)"
    echo "  apt install jq       (Linux)"
    echo ""
    echo "Or manually add to $SETTINGS_FILE:"
    echo '{'
    echo '  "statusLine": {'
    echo '    "type": "command",'
    echo "    \"command\": \"$STATUS_SCRIPT\""
    echo '  }'
    echo '}'
    exit 1
fi
