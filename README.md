# flatina/skills

Agent skills by flatina. Compatible with [skills.sh](https://skills.sh) and [flget](https://github.com/flatina/flget).

## Installation

```bash
npx skills add flatina/skills
```

Use [flget](https://github.com/flatina/flget) to generate typescript shim:

```bash
flget skills add flatina/skills

# script shim is especially effective with local llm
cowsay "moo"
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [cowsay-ts](skills/cowsay-ts) | ASCII cowsay via TypeScript (bun or node, no deps) |
| [flcap-win](skills/flcap-win) | Capture a visible Windows window to PNG |
| [quickening](skills/quickening) | Quiz-based session transfer — alternative to `/compact` and handoff docs. Old session generates verification questions, new session answers by investigating the codebase |
