---
name: quickening
description: >
  Quiz-based session transfer. Elder generates and grades; scion answers,
  probes for clarity, and integrates the reply.
disable-model-invocation: true
argument-hint: "quiz|answer|grade|probe|reply|end (or 1-6) [custom instructions]"
---

Phases by name or number: 1=quiz, 2=answer, 3=grade, 4=probe, 5=reply, 6=end.
If the first argument matches a phase name or number, read the corresponding `references/<name>.md`.
Otherwise default to `references/quiz.md` — treat all arguments as custom instructions.
If no argument given, ask which phase.

$ARGUMENTS
