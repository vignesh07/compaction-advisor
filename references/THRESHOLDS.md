# Context Threshold Reference

## Critical Insight: The Autocompact Buffer

Claude Code doesn't compact at 95% or 100%. It reserves an **autocompact buffer** of approximately **22.5%** (45k tokens on a 200k context window).

**Effective compaction threshold ≈ 77.5%**

This means:
- Total context: 200k tokens
- Autocompact buffer: 45k tokens (22.5%)
- Usable space: 155k tokens (77.5%)
- Compaction triggers when you enter the buffer zone

## Reading /context Output

The `/context` command shows all the data you need:

```
claude-opus-4-5-20251101 · 93k/200k tokens (46%)
                                           ↑ current usage

Free space: 107k (53.6%)     ← USABLE SPACE before compaction
Autocompact buffer: 45.0k    ← RESERVED, cannot use
```

**"Free space" is the key metric** - that's your actual headroom.

## Token Cost Estimates by Task Type

Based on typical Claude Code interactions:

| Task Type | Est. Tokens | Rationale |
|-----------|-------------|-----------|
| **Trivial** | ~5k | Single file, minimal exploration |
| Typo fix | 2-3k | Read file, edit, done |
| Add comment | 3-5k | Read context, write comment |
| **Small** | ~15k | Limited scope, some back-and-forth |
| Bug fix (known) | 10-15k | Read, debug, fix, verify |
| Simple test | 10-15k | Understand function, write test |
| **Medium** | ~30k | Multiple files, exploration |
| New feature | 25-35k | Design, implement, test |
| API endpoint | 25-30k | Route, handler, validation |
| Component | 30-40k | Create, integrate, style |
| **Large** | ~50k | Many files, extensive work |
| Complex feature | 45-60k | Multiple components, edge cases |
| Refactor subsystem | 50-70k | Understand, redesign, migrate |
| Debug complex | 40-60k | Explore, hypothesize, test, fix |
| **Very Large** | ~80k+ | Deep analysis, many iterations |
| Architecture | 70-100k | System-wide understanding |
| Codebase exploration | 60-100k | Reading many files |
| Major migration | 80-120k | Old + new system context |

## Decision Matrix

Compare estimated task tokens to free space:

| Free Space | Safe For | Recommended Action |
|------------|----------|-------------------|
| 80k+ | Any task | Proceed |
| 60-80k | Large or smaller | Monitor very large tasks |
| 40-60k | Medium or smaller | Compact before large tasks |
| 20-40k | Small only | Compact before medium+ tasks |
| <20k | Trivial only | Compact immediately |

## The Math

```
should_compact = estimated_task_tokens > free_space * 0.8

# Include 20% safety margin for estimation variance
```

Example:
- Free space: 50k
- Task: Medium feature (~30k)
- Check: 30k > 50k × 0.8 (40k)? No
- Result: Proceed, but it's borderline

Example 2:
- Free space: 35k
- Task: Large refactor (~50k)
- Check: 50k > 35k × 0.8 (28k)? Yes
- Result: COMPACT NOW

## Status Line Indicators

The status script shows free space with color coding:

| Free Space | Indicator | Meaning |
|------------|-----------|---------|
| 60k+ | 🟢 | Safe for any task |
| 40-60k | 🟡 | Monitor large tasks |
| 20-40k | 🟠 | Compact before medium+ |
| <20k | 🔴 | Compact immediately |

## Multi-Task Planning

When multiple tasks are queued:

1. Sum individual token costs
2. Add 15% overhead for context switching
3. Compare to free space
4. Plan compaction points between major tasks

Example:
```
Tasks:
1. Fix bug (15k)
2. Add feature (30k)
3. Write tests (15k)
Subtotal: 60k
+ 15% overhead: 69k

Free space: 50k
Gap: 19k short

Strategy:
- Complete task 1 (uses ~15k, leaves ~35k)
- Run /compact (recovers to ~100k+ free)
- Complete tasks 2-3 (uses ~50k)
```

## Optimizing Compaction

### When to Compact Proactively

- Before starting any large task
- When free space drops below 40k
- Before multi-file refactors
- Before deep codebase exploration
- At natural breakpoints in work

### Compact with Focus Instructions

Preserve important context:

```
/compact Focus on the auth system changes we discussed
/compact Keep the API error patterns and test failures
/compact Prioritize the database schema and migration plan
```

### When NOT to Compact

- Mid-task (disrupts flow, loses nuance)
- When free space is 60k+ (unnecessary)
- For trivial tasks (just do them)

## Calibrating for Your Workflow

The token estimates above are averages. Your actual usage may vary based on:

- **Codebase size**: Larger files = more tokens per read
- **Exploration style**: Thorough exploration uses more
- **Edit frequency**: Many small edits vs. few large ones
- **Error debugging**: Retry loops consume tokens quickly

Track your actual compaction triggers to calibrate:

1. Note free space when starting tasks
2. See when compaction triggers
3. Adjust personal estimates accordingly

## Technical Details

### How Tokens Are Counted

From `/context` output:
- System prompt: ~3k (fixed)
- System tools: ~19k (fixed)
- Custom agents: varies (~3k typical)
- Memory files: varies (~2k typical)
- Messages: grows with conversation

### Model Context Windows

| Model | Total | Buffer (~22.5%) | Usable |
|-------|-------|-----------------|--------|
| Opus 4.5 | 200k | 45k | 155k |
| Sonnet | 200k | 45k | 155k |
| Haiku | 200k | 45k | 155k |

### Cache Behavior

Cached tokens count toward usage but are cheaper:
- `input_tokens`: Regular input
- `cache_creation_input_tokens`: First use of cached content
- `cache_read_input_tokens`: Subsequent cache hits

All three count toward context limit.
