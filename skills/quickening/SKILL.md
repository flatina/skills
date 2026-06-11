---
name: quickening
description: >
  Quiz-based session transfer over flbus. Elder generates and grades; scion
  answers, probes for clarity, and integrates the reply — hands-free.
disable-model-invocation: true
argument-hint: "(default: elder side) | scion [custom instructions]"
---

Phases: quiz → answer → grade → probe → reply → end. Elder runs quiz, grade, reply; scion runs answer, probe, end. Each phase's work is in `references/<name>.md`.

Routing:
- No argument → elder side: read `references/quiz.md` and begin.
- `scion` → scion side: read `references/answer.md` and begin. Safe to start before the elder finishes — a quiz already sent is delivered instantly when you arm the watcher.

Requires the `flbus` command on PATH (`npm i -g @flatina/flbus`, needs bun); if it is missing, say so and stop. Treat remaining arguments as custom instructions.

## Flow

Transport — each phase's output travels as the flbus message body; the summary names the recipient's next phase. Drive flbus through its command (`flbus <cmd>`); never touch flbus storage dirs directly:
- Same-folder (elder & scion share one folder): each claims its role once (`flbus claim <elder|scion>`), which creates its mailbox. Address the peer `here:<role>` (e.g. `here:scion`); make a peer's mailbox first if it hasn't claimed yet (`flbus mailbox add <role>`).
- Cross-project (the peer is a registered project, /flbus:peer): address it `<peer>:<role>` — its mailbox auto-creates on first send.
- Reply to a received message's `from`: `here:<from>` same-folder, `<peer>:<from>` cross-project.

Turn cycle, after finishing each phase:
1. Send your output as the body; the summary names the recipient's next phase:

```
flbus send --to <addr> --subject quickening --summary "quickening → run <recipient's next phase>" --body-stdin <<'EOF'
<your phase output>
EOF
```

2. Arm the watcher as a background task and end the turn: `flbus listen` — no flags.
3. The watcher's output IS the message: read the body, then read `references/<the phase the summary names>.md` and run it.

The sequence itself ends the exchange: the elder's last phase is reply, the scion's is end. After reply the elder re-arms the watcher and stays available for late questions until the user closes it.

$ARGUMENTS
