# Compaction Advisor Setup

Run the setup script to automatically configure the status line:

```bash
~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/scripts/setup.sh
```

This script will:
1. Find the plugin installation path
2. Update ~/.claude/settings.json with the statusLine configuration
3. Tell the user to restart Claude Code

After running, remind the user to restart Claude Code for changes to take effect.
