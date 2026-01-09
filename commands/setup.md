# Compaction Advisor Setup

Configure compaction-advisor (one-time setup).

Run this command:

```bash
bash -c 'ls -d ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/scripts/setup.sh 2>/dev/null | tail -1 | xargs bash'
```

Then restart Claude Code.

Future plugin updates will auto-apply - no need to re-run setup.
