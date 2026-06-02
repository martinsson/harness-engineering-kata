# Experiment Summary: Making AI Agents Refactor Proactively

## The problem

AI coding agents add logic to existing functions without splitting them up. Functions grow to 100+ lines, nesting deepens to 5-6 levels, classes accumulate attributes — and the agent doesn't react.

## Experimental setup

- **Codebase**: Python warehouse management app with an existing 70-line `process_line` god method
- **Feature prompt**: "implement the feature from feature.md" (stock reservation with expiry — RESERVE, CONFIRM, RELEASE commands)
- **Same prompt every run**, only the harness changes
- **6 techniques tested**, each on its own git branch in an isolated worktree

## Techniques tested

| # | Technique | Type | When it fires |
|---|-----------|------|---------------|
| 1 | UserPromptSubmit hook | Soft context | Before planning |
| 3 | PreToolUse shell script | `ask` gate | Before first edit to each file |
| 4 | PreToolUse agent hook | LLM `ask` gate | Before first edit to each file |
| 10 | Stop hook hard block | Exit code 2 | After every agent turn |
| 11 | Stop hook reviewer agent | LLM block | After every agent turn |
| 14 | Pre-commit violations log | Deferred | At commit time |

## Round 1: Basic rules (function length, cognitive complexity)

| Technique | Flake8 violations | process_line CC | Decomposed? |
|-----------|-------------------|-----------------|-------------|
| userpromptsubmit | 3 | C (18) — 131 lines | No |
| pretooluse-script | **0** | **A (2)** | **Yes — 19 methods** |
| pretooluse-agent | **0** | **A (2)** | **Yes — 16 methods** |
| stop-hard-block | **0** | **A (2)** | **Yes — 16 methods** |
| stop-reviewer | **0** | **A (2)** | **Yes — 16 methods** |
| precommit-log | 4 | C (18) — 146 lines | No |

**Finding**: Any technique with enforcement (`ask`, `exit 2`, agent block) worked. Soft techniques (context injection, deferred logging) were completely ignored.

## Round 2: Stricter rules (magic numbers, string constants, class attrs, file length 150)

| Technique | Violations | Files | Under 150 lines? | Class attrs |
|-----------|-----------|-------|-------------------|-------------|
| userpromptsubmit | 13 | 1 | No (217) | Not checked |
| pretooluse-script | **Broken** (syntax error) | 1 | No | N/A |
| pretooluse-agent | 13 | 1 | No (210) | Not checked |
| **stop-hard-block** | **0** | **5** | **Yes (max 146)** | 8 (not yet checked) |
| stop-reviewer | 0 (flake8) | 4 | No (212) | Not checked |
| precommit-log | 12 | 2 | No (171) | Not checked |

**Finding**: Only `stop-hard-block` scaled to stricter rules. It forced the agent to split into 5 modules. The `ask`-based techniques that worked in round 1 failed here — the non-interactive `-p` mode couldn't handle `ask` prompts well, and the LLM-based reviewer let file length slide.

## Round 3: Added class instance attribute check (max 6, including private)

WPS230 only counts *public* attributes — classes with `self._private` attrs passed silently. A custom AST-based check was added to `check-quality.sh`.

| Technique | Violations | Class attrs | Module structure |
|-----------|-----------|-------------|------------------|
| **stop-hard-block** | **0** | **5 (under 6)** | Stock, OrderBook, ReservationBook, commands, WarehouseDeskApp |

The agent extracted `_price` and `_reserved` into `Stock`, order tracking into `OrderBook`, reservations into `ReservationBook` — a genuinely clean domain decomposition.

## Why things worked or didn't

### What works: Mechanical hard blocking (exit code 2 on Stop hook)

- The agent literally cannot finish responding until the quality script returns exit 0
- Every rule you add to the script is enforced — the agent keeps iterating
- No LLM judgment involved — objective, deterministic checks
- Scales linearly: more rules = more refactoring, never ignored

### What partially works: LLM-based reviewer (Stop hook agent)

- Achieved zero flake8 violations but let file length slide
- The reviewer reasons about "is this worth blocking?" — it exercises judgment, and sometimes judges wrong
- More expensive (extra LLM call per turn)

### What failed: Soft context injection (UserPromptSubmit, additionalContext)

- The agent sees the message but deprioritizes it under task pressure
- "Make the change easy first" is good advice that the agent consistently ignores
- No enforcement mechanism = no behavior change

### What failed: Deferred enforcement (pre-commit violations log)

- PostToolUse logs violations via `additionalContext` — equally ignorable
- Pre-commit gate never fires in non-interactive mode (agent doesn't commit)
- Even if it did fire, the feedback loop is too late — the agent already wrote all the code

### What failed under pressure: `ask`-based PreToolUse hooks

- Worked in round 1 with simple rules
- In non-interactive mode with stricter rules, the `ask` prompt interaction broke or was ineffective
- The shell script variant produced a syntax error in the output

## The winning configuration

**Tag**: `quality-gate-experiment-v1`

Three files make it work:

1. **`.claude/settings.json`** — hooks the Stop event to a quality gate script
2. **`.claude/hooks/stop-quality-gate.sh`** — runs the quality check, exit 2 if violations
3. **`.claude/hooks/check-quality.sh`** — combined flake8 + custom checks

The `.flake8` config and `check-quality.sh` are reusable across projects — they don't depend on any Claude Code specifics.

## Key insight

> The agent doesn't need to understand *why* it should refactor. It needs to be mechanically prevented from finishing until the code is clean. Understanding is optional; enforcement is not.
