#!/bin/bash
# Compaction Advisor - One-Line Installer
#
# Install with:
#   curl -fsSL https://raw.githubusercontent.com/USER/compaction-advisor/main/install.sh | bash
#
# Or clone and run:
#   git clone https://github.com/USER/compaction-advisor.git
#   cd compaction-advisor && ./install.sh

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/USER/compaction-advisor/main"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║       Compaction Advisor Install      ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Create directories
mkdir -p "$CLAUDE_DIR/status"

# Determine script source (local or remote)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/scripts/context_status.sh" ]; then
    # Local install from cloned repo
    echo "📁 Installing from local files..."
    cp "$SCRIPT_DIR/scripts/context_status.sh" "$CLAUDE_DIR/status/context_status.sh"
    cp "$SCRIPT_DIR/scripts/inject_context.sh" "$CLAUDE_DIR/inject_context.sh"
else
    # Remote install via curl
    echo "🌐 Downloading from GitHub..."
    curl -fsSL "$REPO_URL/scripts/context_status.sh" -o "$CLAUDE_DIR/status/context_status.sh"
    curl -fsSL "$REPO_URL/scripts/inject_context.sh" -o "$CLAUDE_DIR/inject_context.sh"
fi

chmod +x "$CLAUDE_DIR/status/context_status.sh"
chmod +x "$CLAUDE_DIR/inject_context.sh"

echo "✓ Scripts installed"

# Configure hook in settings.json
echo "⚙️  Configuring hook..."

HOOK_CONFIG='{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/inject_context.sh"
    }
  ]
}'

if [ -f "$SETTINGS_FILE" ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

    # Check if UserPromptSubmit hook already exists
    if jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1; then
        # Check if our hook is already there
        if jq -e '.hooks.UserPromptSubmit[] | select(.hooks[]?.command == "~/.claude/inject_context.sh")' "$SETTINGS_FILE" > /dev/null 2>&1; then
            echo "✓ Hook already configured"
        else
            # Append our hook to existing array
            jq ".hooks.UserPromptSubmit += [$HOOK_CONFIG]" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            echo "✓ Hook added to existing configuration"
        fi
    else
        # Add new UserPromptSubmit hook
        jq ".hooks.UserPromptSubmit = [$HOOK_CONFIG]" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "✓ Hook configured"
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
    echo "✓ Settings created with hook"
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║          Installation Complete        ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "  1. Open Claude Code"
echo "  2. Run: /config"
echo "  3. Set status line to:"
echo "     ~/.claude/status/context_status.sh"
echo "  4. Restart Claude Code"
echo ""
echo "What you'll see:"
echo ""
echo "  Status line: [Opus] 🟢 85k free ████░░░░░░"
echo ""
echo "  When context gets low, Claude automatically"
echo "  knows and will advise you to /compact"
echo ""
echo "Files installed:"
echo "  ~/.claude/status/context_status.sh"
echo "  ~/.claude/inject_context.sh"
echo ""
