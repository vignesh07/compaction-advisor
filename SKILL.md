---
name: compaction-advisor
description: Provides context-aware compaction guidance. When context is low, you will see a <context-status> tag with the current state. Use this to advise users on compaction timing.
license: MIT
compatibility: Claude Code CLI with hooks enabled
---

# Compaction Advisor

You receive automatic context status via `<context-status>` tags when context is concerning.

## Understanding Context Status

When you see these tags, context is getting low:

```
<context-status>CRITICAL: Only 12k tokens free. Run /compact before any task.</context-status>
<context-status>WARNING: 25k tokens free. Only small tasks safe.</context-status>
<context-status>CAUTION: 40k tokens free. Medium tasks OK, compact before large.</context-status>
```

When context is healthy (50k+ free), you won't see any tag.

## How to Respond

### When you see CRITICAL

Immediately advise:
```
Context is critically low (12k free). Before we proceed, run:
/compact Focus on [relevant context to preserve]
```

### When you see WARNING

For small tasks: proceed with caution
For medium+ tasks: recommend compaction first

```
Context is at 25k free. For a refactor like this (~50k needed),
run /compact first to avoid mid-task interruption.
```

### When you see CAUTION

Mention it briefly, especially for large tasks:
```
Note: Context is at 40k free. This feature should fit, but if it
grows complex, we may want to compact partway through.
```

### When you see nothing

Context is healthy. Proceed normally without mentioning it.

## Task Size Reference

| Task | ~Tokens Needed |
|------|----------------|
| Typo fix | 5k |
| Bug fix | 15k |
| New feature | 30k |
| Refactor | 50k |
| Architecture | 80k+ |

## Compact Commands

```
/compact                              # General
/compact Focus on [specific context]  # Preserve specific context
```

Examples:
- `/compact Focus on the auth changes we discussed`
- `/compact Keep the error patterns and test failures`

## Key Points

- You automatically receive context state - no need to ask user
- Only warn when `<context-status>` appears
- Match urgency to the tag level (CRITICAL > WARNING > CAUTION)
- For healthy context, work normally without mentioning it
