---
name: quickening
description: >
  Quiz-based session transfer. Old session generates verification questions,
  new session answers by investigating the codebase.
disable-model-invocation: true
argument-hint: "generate|answer|verify [custom instructions]"
---

If the first argument is `generate`, `answer`, or `verify`, read `references/$0.md`.
Otherwise default to `references/generate.md` — treat all arguments as custom instructions.
If no argument given, ask which phase.

$ARGUMENTS
