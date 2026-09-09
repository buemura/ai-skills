# AI Skills

A collection of custom [AI skills](https://docs.anthropic.com/en/docs/claude-code/skills) that enhance AI performance across common software development workflows.

## What Are Skills?

Skills are reusable prompt files that give Claude Code specialized behavior for specific tasks. They live in `.claude/skills/` and are automatically triggered based on what you ask Claude to do.

## Included Skills

### Software Engineer (`/engineer`)

An expert software engineering skill for implementing features, fixing bugs, and writing production-quality code.

**Triggers on:** "implement X", "fix bug", "refactor this", "write tests for", "the tests are failing", or any request to change, debug, or improve code.

**What it does:**

- Explores and understands the codebase before making changes
- Plans implementation for non-trivial changes
- Follows code quality standards (SRP, DRY, clear naming, proper error handling)
- Writes and runs tests using AAA pattern
- Performs self-review before presenting changes
- Applies a security-first mindset (injection prevention, input validation, secrets management)

**Includes language-specific references for:**

- [Python](/.claude/skills/engineer/references/python.md) — type hints, async patterns, idiomatic Python, pytest
- [TypeScript](/.claude/skills/engineer/references/typescript.md) — strict mode, generics, Result types, Vitest
- [Testing](/.claude/skills/engineer/references/testing.md) — AAA pattern, mocking strategy, framework quick reference (pytest, Jest/Vitest, Go)

### Project Manager (`/project-manager`)

A senior product manager skill that analyzes your codebase and proposes prioritized feature ideas.

**Triggers on:** "what features should I add", "help me improve my product", "what should I build next", "give me feature ideas", or sharing a codebase for improvement suggestions.

**What it does:**

- Scans project structure, README, and tech stack
- Identifies UX gaps, growth opportunities, and technical debt
- Proposes 6+ features grouped by priority tier (Quick Wins, Core Improvements, Growth Features, Differentiators, Future Bets)
- Provides a 3-phase roadmap with concrete implementation hints
- Calibrates suggestions to project size and maturity

## Installation

Clone this repo and copy the `.claude/skills/` directory into your project:

```bash
# Copy all skills into your project
cp -r .claude/skills/ /path/to/your-project/.claude/skills/
```

Or cherry-pick individual skills:

```bash
# Copy only the engineer skill
cp -r .claude/skills/engineer/ /path/to/your-project/.claude/skills/engineer/

# Copy only the project manager skill
cp -r .claude/skills/project-manager/ /path/to/your-project/.claude/skills/project-manager/
```

## Structure

```
.claude/
  skills/
    engineer/
      SKILL.md                     # Main skill prompt
      references/
        python.md                  # Python best practices
        typescript.md              # TypeScript best practices
        testing.md                 # Testing patterns (pytest, Jest, Go)
    project-manager/
      SKILL.md                     # Main skill prompt
```

## Contributing

To add a new skill, create a directory under `.claude/skills/` with a `SKILL.md` file containing the frontmatter (`name`, `description`) and the skill prompt. See existing skills for the format.

## License

MIT
