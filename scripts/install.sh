#!/bin/bash
# Compaction Advisor - Installation Script
#
# Installs:
# 1. Status line script (visual display + writes state file)
# 2. UserPromptSubmit hook (injects context state into Claude's context)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "Compaction Advisor - Installation"
echo "=================================="
echo ""

# Create directories
mkdir -p "$CLAUDE_DIR/status"

# Copy status line script
echo "1. Installing status line script..."
cp "$SCRIPT_DIR/context_status.sh" "$CLAUDE_DIR/status/context_status.sh"
chmod +x "$CLAUDE_DIR/status/context_status.sh"

# Copy hook script
echo "2. Installing context injection hook..."
cp "$SCRIPT_DIR/inject_context.sh" "$CLAUDE_DIR/inject_context.sh"
chmod +x "$CLAUDE_DIR/inject_context.sh"

# Update settings.json
echo "3. Configuring Claude Code settings..."

if [ -f "$SETTINGS_FILE" ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

    # Add hook if not present
    if ! jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1; then
        # Add UserPromptSubmit hook
        jq '.hooks.UserPromptSubmit = [{"matcher": "", "hooks": [{"type": "command", "command": "~/.claude/inject_context.sh"}]}]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "   Added UserPromptSubmit hook"
    else
        echo "   UserPromptSubmit hook already exists (check manually if you want to add inject_context.sh)"
    fi
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/inject_context.sh"
          }
        ]
      }
    ]
  }
}
EOF
    echo "   Created settings.json with hook"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure the status line in Claude Code:"
echo "   - Run: /config"
echo "   - Navigate to 'Status line'"
echo "   - Set command to: ~/.claude/status/context_status.sh"
echo ""
echo "2. Restart Claude Code for hooks to take effect"
echo ""
echo "How it works:"
echo "  - Status line shows: [Opus] 🟢 85k free ████░░░░░░"
echo "  - When context gets low, Claude automatically sees a warning"
echo "  - No user intervention needed!"
echo ""
echo "Files installed:"
echo "  ~/.claude/status/context_status.sh  (status line)"
echo "  ~/.claude/inject_context.sh         (hook)"
echo "  ~/.claude/settings.json             (configuration)"
echo ""
