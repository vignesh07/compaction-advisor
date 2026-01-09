#!/bin/bash
# Compaction Advisor - Auto Setup Script
#
# Creates wrapper scripts at fixed locations that call plugin scripts.
# This way plugin updates don't break paths AND scripts auto-update.

set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"
STATUS_DIR="$HOME/.claude/status"
WRAPPER_SCRIPT="$STATUS_DIR/context_status.sh"

echo "Setting up Compaction Advisor..."

# Create wrapper script that finds and calls the latest plugin version
mkdir -p "$STATUS_DIR"
cat > "$WRAPPER_SCRIPT" << 'WRAPPER'
#!/bin/bash
# Wrapper that calls the latest compaction-advisor plugin version
PLUGIN_SCRIPT=""
for path in "$HOME/.claude/plugins/cache/compaction-advisor/compaction-advisor"/*/scripts/context_status.sh; do
    [ -f "$path" ] && PLUGIN_SCRIPT="$path"
done
if [ -n "$PLUGIN_SCRIPT" ] && [ -x "$PLUGIN_SCRIPT" ]; then
    exec "$PLUGIN_SCRIPT"
else
    echo "[?] compaction-advisor not found"
fi
WRAPPER
chmod +x "$WRAPPER_SCRIPT"
echo "Created wrapper: $WRAPPER_SCRIPT"

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS_FILE" ]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo '{}' > "$SETTINGS_FILE"
fi

# Configure statusLine to use wrapper
jq --arg cmd "$WRAPPER_SCRIPT" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# Remove any user-level hooks (plugin's hooks.json handles it with ${CLAUDE_PLUGIN_ROOT})
if jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1; then
    jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[]?.command | contains("compaction-advisor") or contains("inject_context")))' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    jq 'if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    jq 'if .hooks == {} then del(.hooks) else . end' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "Cleaned up old hooks from settings.json"
fi

echo ""
echo "SUCCESS!"
echo "  Status line: $WRAPPER_SCRIPT (auto-finds latest plugin version)"
echo "  Hooks: Plugin's hooks.json (auto-updates with plugin)"
echo ""
echo ">>> Restart Claude Code to activate <<<"
