# Compaction Advisor Setup

Configure compaction-advisor (one-time setup).

## Steps

1. Find and run the setup script:

```bash
for script in ~/.claude/plugins/cache/compaction-advisor/compaction-advisor/*/scripts/setup.sh; do [ -f "$script" ] && bash "$script" && break; done
```

2. Tell user to restart Claude Code.

The setup creates a wrapper at `~/.claude/status/context_status.sh` that auto-finds the latest plugin version. Future updates won't require re-running setup.
