# 🧠 Compaction Advisor

> Automatic context monitoring for Claude Code — never get interrupted by mid-task compaction again.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://claude.ai/code)

---

## 📦 Installation

### Option 1: Plugin Marketplace (Recommended)

```bash
/plugin marketplace add vignesh07/compaction-advisor
/plugin install compaction-advisor
/compaction-advisor:setup
```

Then restart Claude Code. That's it!

### Option 2: One-Line Install (without plugin system)

```bash
curl -fsSL https://raw.githubusercontent.com/vignesh07/compaction-advisor/main/install.sh | bash
```

Then restart Claude Code.

---

## 🎯 The Problem

Claude Code auto-compacts when your context window fills up. This often happens **mid-task** — right when you're deep in a refactor or debugging session. You lose important context, and Claude has to rediscover things it already knew.

**The worst part?** By the time you see the warning, it's too late.

## ✨ The Solution

**Compaction Advisor** gives Claude real-time awareness of context usage. No user intervention needed.

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  Status Line:  [Opus] 🟠 25k free ████████░░               │
│                                                            │
│  You: I want to refactor the authentication system         │
│                                                            │
│  Claude: Context is at 25k free — that's tight for a       │
│          refactor (~50k needed). Run /compact first to     │
│          avoid interruption?                               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

Claude **automatically knows** when context is low and proactively advises you.

---

## 📊 How It Works

Two lightweight components work together:

```
┌─────────────────┐         ┌─────────────────────────┐
│   Status Line   │         │  UserPromptSubmit Hook  │
│   (for you)     │         │     (for Claude)        │
└────────┬────────┘         └────────────┬────────────┘
         │                               │
         ▼                               ▼
   Displays in UI              Runs on every prompt
         │                               │
         ▼                               ▼
┌─────────────────┐         ┌─────────────────────────┐
│ 🟠 25k free     │────────▶│ Reads state file        │
│ ████████░░      │  writes │ Injects into Claude     │
└─────────────────┘         └─────────────────────────┘
                                        │
                                        ▼
                            ┌─────────────────────────┐
                            │ Claude sees:            │
                            │ <context-status>        │
                            │ WARNING: 25k free...    │
                            │ </context-status>       │
                            └─────────────────────────┘
```

**When context is healthy → hook stays silent (0 tokens)**

---

## 🧠 Why It Works: Natural Language Understanding

This plugin doesn't use pattern matching or hardcoded rules. It simply **gives Claude information** and lets it reason naturally.

```
┌─────────────────────────────────────────────────────────────┐
│ You type: "can you do a full refactor of this codebase?"    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Hook injects context state:                                 │
│ <context-status>CRITICAL: Only 13k tokens free.</context>   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude sees BOTH pieces of information:                     │
│ • Context is critically low (13k free)                      │
│ • User wants a refactor (~50k tokens needed)                │
│                                                             │
│ Claude naturally reasons: 13k < 50k → warn user             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude responds:                                            │
│ "Context is at 13k free. A refactor needs ~50k.             │
│  Run /compact first to avoid mid-task interruption."        │
└─────────────────────────────────────────────────────────────┘
```

**No prediction needed.** The plugin provides facts, Claude reasons about them.

| Request | Claude's Reasoning |
|---------|-------------------|
| "refactor the app" | Big task (~50k) vs 13k free → warn |
| "add a small feature" | Medium task (~30k) vs 13k free → warn |
| "fix this typo" | Tiny task (~5k) vs 13k free → proceed |
| "rewrite everything" | Huge task (~80k) vs 13k free → definitely warn |

This is the power of LLMs — natural understanding, not brittle pattern matching.

---

## 🚦 Status Indicators

| Status Line | Free Space | What It Means | Claude Sees |
|-------------|------------|---------------|-------------|
| 🟢 `85k free` | 50k+ | Safe for any task | Nothing (silent) |
| 🟡 `42k free` | 30-50k | Medium tasks OK | `CAUTION` message |
| 🟠 `25k free` | 15-30k | Small tasks only | `WARNING` message |
| 🔴 `COMPACT` | <15k | Compact NOW | `CRITICAL` message |

---

## 💰 Token Cost

Designed to be **extremely lightweight**:

| Context State | Tokens Added |
|---------------|--------------|
| 🟢 Healthy (50k+ free) | **0** |
| 🟡 Caution | ~20 |
| 🟠 Warning | ~25 |
| 🔴 Critical | ~18 |

**Most of the time: zero tokens.** The hook only injects when context is actually concerning.

---

## 📏 Task Size Reference

Use this to gauge if you have enough headroom:

| Task Type | Estimated Tokens |
|-----------|------------------|
| Typo fix, add comment | ~5k |
| Bug fix, simple test | ~15k |
| New feature, API endpoint | ~30k |
| Refactor, complex debug | ~50k |
| Architecture overhaul | ~80k+ |

**Rule of thumb:** If `free space < task estimate`, run `/compact` first.

---

## 🔒 Security

This plugin:

- ✅ **Runs locally** — no external API calls
- ✅ **No data collection** — nothing leaves your machine
- ✅ **Minimal permissions** — only reads Claude Code's context data
- ✅ **Open source** — full code visibility
- ✅ **No network access** — pure shell scripts

### What the scripts do:

| Script | Purpose |
|--------|---------|
| `context_status.sh` | Reads JSON from Claude Code stdin, calculates free space, writes to local file |
| `inject_context.sh` | Reads local state file, outputs warning text if concerning |

Both scripts are simple bash — inspect them yourself in `/scripts/`.

---

## 🔧 Technical Details

### Context Window Math

```
Total context:        200,000 tokens
Autocompact buffer:   ~45,000 tokens (22.5%)
─────────────────────────────────────
Usable space:         ~155,000 tokens

Free space = Usable - Current usage
```

The status line shows **free space before compaction triggers**, not total context remaining.

### How Claude Code Provides Data

The status line receives JSON via stdin:

```json
{
  "context_window": {
    "context_window_size": 200000,
    "current_usage": {
      "input_tokens": 93000,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 8000
    }
  }
}
```

---

## 📁 Project Structure

```
compaction-advisor/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   └── marketplace.json      # Marketplace listing
├── commands/
│   ├── setup.md              # /compaction-advisor:setup command
│   └── test.md               # Diagnostic command
├── hooks/
│   └── hooks.json            # UserPromptSubmit hook
├── scripts/
│   ├── context_status.sh     # Status line script
│   ├── inject_context.sh     # Hook injection script
│   └── setup.sh              # Auto-setup for status line
├── references/
│   └── THRESHOLDS.md         # Detailed threshold math
├── install.sh                # One-line curl installer
├── SKILL.md                  # Claude instructions
├── LICENSE                   # MIT
└── README.md
```

---

## 🗑️ Uninstall

```bash
rm ~/.claude/status/context_status.sh
rm ~/.claude/inject_context.sh
rm ~/.claude/context_state.json
```

Then remove the hook from `~/.claude/settings.json` (or reinstall the plugin without hooks).

---

## 📄 License

MIT — use it however you want.

---

## 💡 Why This Exists

Mid-task compaction is frustrating:
- You lose nuanced understanding of your codebase
- Claude has to re-read files it already knew
- Flow state is broken
- Important debugging context vanishes

**Proactive compaction** puts you in control:
- You decide when to compact
- You specify what context to preserve
- No surprise interruptions
- Better output quality

---

<p align="center">
  <i>Built with Claude Code 🤖</i>
</p>
