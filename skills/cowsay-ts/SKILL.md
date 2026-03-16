---
name: cowsay-ts
description: ASCII cowsay via TypeScript (bun or node, no deps). Trigger on "cowsay", "cow say", "make a cow say", "moo", or ASCII cow requests.
allowed-tools:
  - Bash(bun *cowsay.ts*)
  - Bash(npx tsx *cowsay.ts*)
  - Bash(cowsay *)
shims:
  - scripts/cowsay.ts
---

# cowsay-ts

Pure TypeScript cowsay. Runs with bun or node (via tsx/ts-node), no external dependencies.

## Usage

```bash
# bun
bun run scripts/cowsay.ts "message"

# node
npx tsx scripts/cowsay.ts "message"

# shim (installed by flget)
cowsay "message"
```

Defaults to "Moo!" if no text is given. Long text auto-wraps at 40 characters.

Always present output in a fenced code block — monospace is required for alignment.
