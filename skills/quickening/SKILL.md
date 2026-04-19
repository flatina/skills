---
name: quickening
description: >
  Quiz-based session transfer. Old session generates questions and verifies answers;
  new session investigates, answers, and integrates feedback.
disable-model-invocation: true
argument-hint: "generate|answer|verify|end [custom instructions]"
---

If the first argument is `generate`, `answer`, `verify`, or `end`, read `references/$0.md`.
Otherwise default to `references/generate.md` — treat all arguments as custom instructions.
If no argument given, ask which phase.

$ARGUMENTS
