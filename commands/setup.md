# Compaction Advisor Setup

Configure compaction-advisor (one-time setup).

Run this command:

```bash
bash -c 'for s in ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/scripts/setup.sh; do [ -f "$s" ] && bash "$s" && break; done'
```

Then restart Claude Code.

Future plugin updates will auto-apply - no need to re-run setup.
