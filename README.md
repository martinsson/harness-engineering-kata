# Harness engineering kata

Experiment with tweaking and tooling the harness of agents so they produce the result you want.

Implement the same feature over and over again, improve the harness to make it generate better an better versions of it

By harness in this context we mean whatever influences the agent's behavior, and whatever feedback mechanisms you put in place.
- the AGENTS.md / CLAUDE.md file
- skills
- scripts (making results predictable)
- Architectural documents, and constraints (like arch unit)
- Process / workflow descriptions
- the README.md and other visible files in the root dir


## Prerequisites

Install quality checking tools (needed for steps 6-7):

```bash
# Python
pip install -r python/requirements-dev.txt

# Java — add checkstyle plugin to pom.xml (see "Quality tools by language" below)
```
## Claude code (Optional)

For a "fresh" clade code instance, set a "new" claude config dir
```bash
export CLAUDE_CONFIG_DIR=~/.claude_hek
```
_CLAUDE_CONFIG_DIR	Override the configuration directory (default: \~/.claude). All settings, credentials, session history, and plugins are stored under this path. Useful for running multiple accounts side by side: for example, alias claude-work='CLAUDE_CONFIG_DIR=\~/.claude-work claude'_ https://code.claude.com/docs/en/env-vars


## Steps
For each step, throw away all code and get back to main, use this prompt, unless instructed otherwise:

    implement the feature from feature.md

### 1. No Harness

  Start without any harness files, and do not create AGENTS.md or CLAUDE.md.

### 2. Add a Minimal Agent Instruction File

  Create either AGENTS.md or CLAUDE.md and add a simple instruction such as: "Add full test coverage for new features."

### 3. Add Regression-Protection Guidance

  Assume the agent may skip tests for existing untested code, and add an instruction like: "To protect against regressions, always add full coverage for existing code before modifying it."

### 4. Refactor Until Quality Is Acceptable

  Assume the initial code quality is weak, ask the agent to refactor repeatedly until you are reasonably satisfied, and then ask it to extract design principles from the conversation into a file such as
  docs/design-principles.md.

### 5. Reuse Design Principles and Retry

  Reference docs/design-principles.md from AGENTS.md or CLAUDE.md, then restart from scratch and compare whether the resulting code is similar to the improved result from the first iteration.

### 6. Add a Code Quality Gate via Stop Hook (Reviewer Agent)

  Activate a Stop hook that spawns a reviewer sub-agent after each agent turn. The reviewer runs the linter, reads offending functions, and decides whether to block or allow.

  ```bash
  cp harness/step-6/settings.json .claude/settings.json
  ```

  Restart your Claude Code / Copilot session, then run the prompt.

### 7. Add a Mechanical Quality Gate via Stop Hook (Hard Block)

  Replace the reviewer agent with a deterministic quality gate. The Stop hook runs a linter and custom checks — if any violation exists, exit code 2 blocks the agent from finishing. The agent is forced to iterate until the code is clean. This is the most effective technique found in the quality gate experiment (see [Discussion](#discussion)).

  ```bash
  cp harness/step-7/settings.json .claude/settings.json
  ```

  Restart your Claude Code / Copilot session, then run the prompt.

  The hook scripts (`.claude/hooks/stop-quality-gate.sh`, `.claude/hooks/check-quality.sh`) and linter config (`python/.flake8`) are already in the repo — the settings file above activates them.

### 8. Add a TDD Skill Through Research and Reapplication

  Ask the agent to research what TDD is and how it applies to agent workflows, explain it clearly, create a dedicated TDD skill, and then re-implement the feature using that skill.

### 9. Add Debugging Capability and Extract a Skill

  Enable the agent to run the app in debug mode, introduce a bug, ask the agent to diagnose and fix it, and then extract that debugging workflow into a reusable skill added to the repository.


## Run

### Java

```bash
cd java
mvn -q compile
java -cp target/classes com.kata.warehouse.Main
```

### Python

```bash
cd python
python main.py
```


## Quality tools by language

### Python

Configured in `python/.flake8` and `.claude/hooks/check-quality.sh`. Checks: function length (30), cognitive complexity (10), magic numbers, string constant overuse, class instance attributes (6), file length (150 lines), max parameters (4).

### Java

Use [Checkstyle](https://checkstyle.org/) for the same checks. A starter `checkstyle.xml` covering method length, parameter count, cyclomatic complexity, magic numbers, string literals, and file length is in `java/checkstyle.xml`. Add the maven-checkstyle-plugin to `pom.xml` and adapt `.claude/hooks/stop-quality-gate.sh` to call `mvn -q checkstyle:check`.

[ArchUnit](https://www.archunit.org/) can additionally enforce architectural constraints (package dependencies, layer separation) as executable tests.


## Discussion

### Quality gate experiment

An experiment compared 6 harness techniques for making AI agents refactor proactively, across 3 rounds of increasing strictness. Full results: [`docs/experiment-summary.md`](docs/experiment-summary.md).

**Techniques tested:** soft context injection (UserPromptSubmit hook), `ask`-based PreToolUse hooks (shell script and LLM agent), hard-blocking Stop hooks (shell script and LLM reviewer), and deferred enforcement (pre-commit violations log).

**Key finding:** Mechanical hard blocking (Stop hook with exit code 2) is the only technique that reliably scales. Soft techniques (context injection, deferred logging) were consistently ignored. LLM-based reviewers worked partially but exercised judgment that sometimes let violations slide.

**Conclusion:** The agent doesn't need to understand *why* it should refactor. It needs to be mechanically prevented from finishing until the code is clean. Understanding is optional; enforcement is not.
