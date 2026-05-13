---
marp: true
title: Harness Engineering
paginate: true
---

# Harness Engineering

Getting LLMs to predictably produce code you'd be proud to ship.

<!--
Live coding session. Slides are skeletal on purpose —
the real content is in the demo.
-->

---

## The core claims

1. LLMs are **excellent at code design**. By default, they produce crap.
2. *What they do* is not the evaluation criterion. *What we can make them do* is.
3. A good **harness** defines the **minimum quality** that will always be produced.
4. Honest engineering = continuously raising that floor.
5. The point of human code review is mostly to **improve the harness**.

<!--
Land these five points. Everything else is illustration.
-->

---

## What is "the harness"?

Anything that shapes how the agent works:

- `AGENTS.md` / `CLAUDE.md`
- Skills
- Workflow & process descriptions
- Referenced documentation (design principles, ADRs)
- Scripts that make outcomes deterministic
- Feedback mechanisms (hooks, gates, reviewers)
- Sub-agents
- The visible state of the repo itself

At **all levels** — from a single prompt to repo-wide enforcement.

---

# 1. The problem

---

## The default output

Same feature, same model, same prompt — wildly different code.

- Inconsistent quality
- Skipped tests
- Magic numbers, long functions, accidental complexity
- Confident-looking, subtly wrong

The model isn't the bottleneck. **The harness is.**

<!--
Show one or two examples here from a clean run with no harness.
-->

---

# 2. Things that influence the output

---

## The levers we have

| Layer | Examples |
|---|---|
| **Instructions** | `AGENTS.md`, `CLAUDE.md`, prompts |
| **Knowledge** | design principles, ADRs, referenced docs |
| **Skills** | TDD, debugging, refactoring playbooks |
| **Process** | workflow steps, gates, review rituals |
| **Tools** | scripts, linters, type checkers, ArchUnit |
| **Feedback** | hooks (pre-tool, stop, pre-commit), sub-agents |
| **Repo shape** | what's visible, runnable, discoverable |

Each lever has a different **cost** and **reliability**.

---

# 3. Experimentation

A feel for how the levers actually behave.

---

## The kata

Implement the **same feature** repeatedly. Improve the harness between runs.

Prompt every time:

```
implement the feature from feature.md
```

Throw the code away. Keep the harness.

---

## Step 1 — No harness

Baseline. What does the model do unsupervised?

<!--
Run it. Show what comes out. Don't editorialize yet.
-->

---

## Step 2 — Minimal `AGENTS.md`

> "Add full test coverage for new features."

One sentence. Does it stick?

---

## Step 3 — Regression protection

> "Before modifying existing code, add full coverage for it."

Closing the obvious loophole.

---

## Step 4 — Refactor until acceptable

Ask the agent to refactor, repeatedly.
Then ask it to **extract its own design principles** into `docs/design-principles.md`.

The agent crunches its own experience into reusable knowledge.

---

## Step 5 — Reuse the principles

Reference `design-principles.md` from `AGENTS.md`. Start over.

Does fresh code now resemble the polished version from step 4?

<!--
This is the "knowledge documents" insight from meta-considerations.
-->

---

## Step 6 — Reviewer sub-agent (soft gate)

Stop hook → spawns a reviewer agent → runs quality script → decides.

Judgement-based. Sometimes lets things slide.

---

## Step 7 — Mechanical quality gate (hard gate)

Same script. **Exit code 2** instead of agent judgement.

The agent **cannot finish** until the code is clean.

> The agent doesn't need to understand *why* to refactor.
> It needs to be **prevented from finishing** until it has.

---

## Step 8 — Research & build a TDD skill

Ask the agent to:
1. Research TDD
2. Explain it
3. Build a TDD skill
4. Re-implement the feature using it

The agent contributes to its own harness.

---

## Step 9 — Debugging as a skill

Plant a bug. Let the agent run the app in debug mode. Fix it.
Then extract the workflow into a reusable skill.

Instrumenting the repo *for the agent*.

---

# 4. Retrospective

What can we trust the agent to succeed at? What not?

---

## Trust matrix (working hypothesis)

| Trust | Verify | Don't trust |
|---|---|---|
| Code design when guided | Adherence to standards | Self-discipline without enforcement |
| Refactoring under pressure | Test coverage claims | "I checked everything" |
| Extracting tacit knowledge | Following extracted skills | Judgement on "good enough" |
| Mechanical fixes | Cross-cutting consistency | Knowing when to stop |

<!--
Invite the audience to push back / add rows.
-->

---

# 5. Retrospective

How do we limit review and correction work?

---

## Make review structural, not heroic

- **Hard gates** catch the mechanical stuff before it reaches you
- **Skills + principles** propagate fixes across future runs
- Human review = *finding the next gate to add*
- Every recurring correction is a **harness bug**, not a code bug

> If you find yourself correcting the same thing twice, fix the harness.

---

# 6. Side issue — Legacy code

Why does this work less well on legacy? What can we do?

---

## Why legacy resists

- No discoverable conventions → defaults win
- No runnable feedback → no gates to hold the line
- Hidden invariants live in people's heads
- Code is the documentation, and the documentation is wrong

The agent has nothing to lean on, so it leans on its priors.

---

## What helps

- **Make it runnable.** Even a partial harness beats none.
- **Extract knowledge from the agent's own exploration** — pin it down as principles, skills, ADRs.
- **Crunch external knowledge** (docs, tickets, slack threads) into harness inputs.
- **Instrument the repo** — scripts that the agent can call to *check itself*.
- **Use the agent to improve its own harness.** Recursive, slow, real.

---

# Takeaways

1. Default output is not the measurement.
2. The harness defines the floor.
3. Hard enforcement > soft suggestion.
4. Human review's highest-leverage output is **a harness change**.
5. The agent can help build its own harness — if you let it.

---

# Thanks

Repo: `harness-engineering-3`
Kata: `README.md` — steps 1 through 9.

Questions → demo → discussion.
