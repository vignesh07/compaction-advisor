# Compaction Advisor

Automatic context monitoring for Claude Code that prevents mid-task compaction interruptions.

## The Problem

Claude Code auto-compacts when context fills up - often mid-task, losing important context and breaking your flow.

## The Solution

**Claude automatically knows when context is low.** No user intervention needed.

```
┌─────────────────────────────────────────────────────────┐
│ Status line: [Opus] 🟠 25k free ████████░░              │
│                                                          │
│ You: I want to refactor the auth system                 │
│                                                          │
│ Claude: (automatically sees context warning)            │
│         Context is at 25k free - that's tight for a    │
│         refactor. Run /compact first?                   │
└─────────────────────────────────────────────────────────┘
```

## Installation

### Option 1: Plugin Marketplace (Recommended)

```bash
/plugin marketplace add vignesh07/compaction-advisor
/plugin install compaction-advisor
```

Then configure the status line:
1. Run `/config`
2. Set status line to the plugin's script (shown after install)

### Option 2: One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/vignesh07/compaction-advisor/main/install.sh | bash
```

Then:
1. Run `/config` in Claude Code
2. Set status line to `~/.claude/status/context_status.sh`
3. Restart Claude Code

### Option 3: Manual Install

```bash
git clone https://github.com/vignesh07/compaction-advisor.git
cd compaction-advisor
./install.sh
```

## How It Works

Two components work together:

1. **Status line script** - Shows real-time context in UI, writes state to file
2. **UserPromptSubmit hook** - Injects context state into Claude's context on each prompt

```
Status Line                    UserPromptSubmit Hook
     │                                  │
     ▼                                  ▼
Writes state to file ──────► Reads file, injects into Claude
     │                                  │
     ▼                                  ▼
User sees: 🟠 25k free        Claude sees: <context-status>WARNING...</context-status>
```

When context is healthy, the hook stays silent (no noise, no tokens).

## Token Cost

Designed to be lightweight:

| Context State | Status Line | Hook Injection | Total Tokens |
|---------------|-------------|----------------|--------------|
| 🟢 Safe (50k+) | 0 (display only) | Silent | **0** |
| 🟡 Caution (30-50k) | 0 | ~20 tokens | **~20** |
| 🟠 Warning (15-30k) | 0 | ~25 tokens | **~25** |
| 🔴 Critical (<15k) | 0 | ~18 tokens | **~18** |

**Most of the time: 0 tokens.** The hook only injects when context is actually concerning.

## Indicators

| Status Line | Free Space | Claude Sees |
|-------------|------------|-------------|
| 🟢 50k+ free | Safe | Nothing (silent) |
| 🟡 30-50k free | OK | `<context-status>CAUTION...</context-status>` |
| 🟠 15-30k free | Low | `<context-status>WARNING...</context-status>` |
| 🔴 COMPACT | Critical | `<context-status>CRITICAL...</context-status>` |

## Task Token Estimates

| Task | ~Tokens |
|------|---------|
| Typo fix | 5k |
| Bug fix | 15k |
| New feature | 30k |
| Refactor | 50k |
| Architecture | 80k+ |

## Technical Details

- Context window: 200k tokens
- Autocompact buffer: ~45k (22.5%)
- Usable before compaction: ~155k tokens

The status line receives JSON from Claude Code with `context_window` data. The hook uses `UserPromptSubmit` to inject context that Claude sees before processing each prompt.

## Project Structure

```
compaction-advisor/
├── .claude-plugin/
│   └── plugin.json           # Plugin configuration
├── hooks/
│   └── hooks.json            # UserPromptSubmit hook
├── scripts/
│   ├── context_status.sh     # Status line + state writer
│   ├── inject_context.sh     # Hook script
│   └── install.sh            # Manual installer
├── references/
│   └── THRESHOLDS.md         # Detailed math
├── install.sh                # Root installer (curl-able)
├── SKILL.md                  # Claude instructions
├── README.md
└── LICENSE
```

## Uninstall

```bash
rm ~/.claude/status/context_status.sh
rm ~/.claude/inject_context.sh
rm ~/.claude/context_state.json
# Remove hook from ~/.claude/settings.json manually
```

## Contributing

- Better token cost calibration
- Support for different model context sizes
- Alternative display formats

## License

MIT
