---
name: quickening
description: >
  Quiz-based session transfer. Elder generates and grades; scion attempts,
  probes for clarity, and integrates the reply.
disable-model-invocation: true
argument-hint: "quiz|attempt|grade|probe|reply|end [custom instructions]"
---

If the first argument is `quiz`, `attempt`, `grade`, `probe`, `reply`, or `end`, read `references/$0.md`.
Otherwise default to `references/quiz.md` — treat all arguments as custom instructions.
If no argument given, ask which phase.

$ARGUMENTS
