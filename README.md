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
| [code-outline](skills/code-outline) | Compact outline of .ts/.js files — top-level functions, classes, types |
| [cowsay-ts](skills/cowsay-ts) | ASCII cowsay via TypeScript (bun or node, no deps) |
| [flcap-win](skills/flcap-win) | Capture a visible Windows window to PNG |
| [quickening](skills/quickening) | Hands-free session transfer over [flbus](https://www.npmjs.com/package/@flatina/flbus) — alternative to `/compact` and handoff docs. An elder session quizzes the fresh scion, which answers by investigating the codebase, then grades and reconciles |
