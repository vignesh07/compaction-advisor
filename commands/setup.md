# Compaction Advisor Setup

Configure the status line automatically. Run this setup script:

```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/ 2>/dev/null | head -1)
if [ -n "$PLUGIN_DIR" ]; then
  bash "$PLUGIN_DIR/scripts/setup.sh"
else
  echo "ERROR: Plugin not installed. Run these first:"
  echo "  /plugin marketplace add vignesh07/compaction-advisor"
  echo "  /plugin install compaction-advisor"
fi
```

After running successfully, tell the user to restart Claude Code for the status line to appear.
