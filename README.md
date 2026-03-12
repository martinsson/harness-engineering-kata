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


## Steps
For each step, throw away all code and get back to main, use this prompt, unless instructed otherwise:

    implement the feature from feature.md

### 1. No Harness

  Start without any harness files, and do not create AGENTS.md or CLAUDE.md.

### 2. Add a Minimal Agent Instruction File

  Create either AGENTS.md or CLAUDE.md and add a simple instruction such as: “Add full test coverage for new features.”

### 3. Add Regression-Protection Guidance

  Assume the agent may skip tests for existing untested code, and add an instruction like: “To protect against regressions, always add full coverage for existing code before modifying it.”

### 4. Refactor Until Quality Is Acceptable

  Assume the initial code quality is weak, ask the agent to refactor repeatedly until you are reasonably satisfied, and then ask it to extract design principles from the conversation into a file such as
  docs/design-principles.md.

### 5. Reuse Design Principles and Retry

  Reference docs/design-principles.md from AGENTS.md or CLAUDE.md, then restart from scratch and compare whether the resulting code is similar to the improved result from the first iteration.

### 6. Make Code Review Mandatory and Actionable

  Have the agent produce a local code-review file when a feature is done, require code review as a standard completion step, turn code reviewing into a skill, and then have the agent fix the issues identified by
  that review.

### 7. Add Architectural Constraints

  Introduce architectural constraints (for example, ArchUnit-style rules) and verify whether the agent uses them to guide feedback and implementation decisions.

### 8. Add a TDD Skill Through Research and Reapplication

  Ask the agent to research what TDD is and how it applies to agent workflows, explain it clearly, create a dedicated TDD skill, and then re-implement the feature using that skill.

### 9. Add Debugging Capability and Extract a Skill

  Enable the agent to run the app in debug mode, introduce a bug, ask the agent to diagnose and fix it, and then extract that debugging workflow into a reusable skill added to the repository.

### 10. Use a tool to criticize your tests 
  E.g. Farley Score Plugin for Claude Code https://github.com/mse-online/farley_score_plugin
Use the tool to criticize your tests and tell your agent to get to the maximum Farley Index of 10.


## Run

```bash
mvn -q compile
java -cp target/classes com.kata.warehouse.Main
```



