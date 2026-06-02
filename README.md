# Warehouse Desk App

This repository contains the same code in different language versions. It usually works better to open the folder for the language you want to use in your IDE or editor, not this one.

You can use this code for an exercise. See [Designing a Harness for Agentic Autonomy](https://sammancoaching.org/learning_hours/agentic_engineering/agentic_harness_part1.html).


## Quality tools by language

### Python

Configured in `harness/step-6/.claude/hooks/check-quality.sh`. Checks: function length (30), cognitive complexity (10), magic numbers, string constant overuse, class instance attributes (6), file length (150 lines), max parameters (4). The flake8 config is in `harness/step-6/python/.flake8`. Both are copied into place when activating step 6 (see step 6 instructions above).

### Java

Use [Checkstyle](https://checkstyle.org/) for the same checks. A starter `checkstyle.xml` covering method length, parameter count, cyclomatic complexity, magic numbers, string literals, and file length is in `harness/step-6/java/checkstyle.xml` — copied into place when activating step 6. Add the maven-checkstyle-plugin to `pom.xml` and adapt `harness/step-6/.claude/hooks/check-quality.sh` to also call `mvn -q checkstyle:check`.

[ArchUnit](https://www.archunit.org/) can additionally enforce architectural constraints (package dependencies, layer separation) as executable tests.


## Discussion

### Quality gate experiment

An experiment compared 6 harness techniques for making AI agents refactor proactively, across 3 rounds of increasing strictness. Full results: [`docs/experiment-summary.md`](docs/experiment-summary.md).

**Techniques tested:** soft context injection (UserPromptSubmit hook), `ask`-based PreToolUse hooks (shell script and LLM agent), hard-blocking Stop hooks (shell script and LLM reviewer), and deferred enforcement (pre-commit violations log).

**Key finding:** Mechanical hard blocking (Stop hook with exit code 2) is the only technique that reliably scales. Soft techniques (context injection, deferred logging) were consistently ignored. LLM-based reviewers worked partially but exercised judgment that sometimes let violations slide.

**Conclusion:** The agent doesn't need to understand *why* it should refactor. It needs to be mechanically prevented from finishing until the code is clean. Understanding is optional; enforcement is not.
