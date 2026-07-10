# Agent Skills Documentation

This directory contains skills for coding agents working on this project.

## Directory Structure

```
.agents/
├── README.md          (this file)
└── skills/
    ├── unit-test-design/
    │   ├── SKILL.md   (main skill definition)
    │   └── [additional resources]
    └── [other-skill-name]/
        └── SKILL.md
```

## About Skills

Skills are modular knowledge files that customize the coding agent's behavior for this project. Each skill:

- **Location**: `.agents/skills/[skill-name]/SKILL.md`
- **Naming**: Subdirectories must be lowercase with hyphens (e.g., `unit-test-design`)
- **Format**: SKILL.md files contain YAML frontmatter and Markdown instructions
- **Required Frontmatter Fields**:
    - `name`: Unique lowercase identifier (matches subdirectory)
    - `description`: What the skill does and when to use it

## How AI Agents should use skills

When working on this project, AI agents should:

1. List `.agents/skills/` for available skills
2. Read only the frontmatter for each SKILL.md, so as not to fill the context with unneeded instructions.
3. Before starting related tasks, read the full SKILL.md file for the relevant skill(s).

## Official Documentation

For more information about creating and managing skills, see:
* Open standard: https://agentskills.io/home
* Codex: https://learn.chatgpt.com/docs/build-skills
* Claude Code: https://code.claude.com/docs/en/skills
* Github Copilot: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
