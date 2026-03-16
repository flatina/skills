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
