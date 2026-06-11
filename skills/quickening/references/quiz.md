# Quiz

Tear down any stale mailbox and claim your role: `flbus mailbox rm elder` then `flbus claim elder`.

This is for the next session's understanding of the project — not a log of what you did this session. Skip anything derivable from source, docs, or git; the next session can re-investigate. Most questions should test understanding outside the area of recent work — if your session's work is complete, that work is now just a small fraction of the project and shouldn't dominate the quiz. Each question should ask about one thing only — don't mix past, present, and next steps in a single question.

The quiz contains:
- Undocumented commitments (if any) — constraints the next session must respect that aren't yet in source or docs. One line each. If it matters long-term, also document it in the project itself. Examples: "user deferred legacy table migration to next sprint", "approach A for now; B prototyped on branch xyz pending review". Don't re-litigate in answers — raise concrete counter-evidence via an open question instead.
- Operating guidance (if any) follows in the same format: rules about how to work, e.g. style, process, principles. Examples: "terse responses, no trailing summaries", "ask before committing", "implement simple structures concisely — no premature abstraction".
- Brief context — only what the next session needs.
- References the next session should read — small critical docs in full. For code references, include a "use LSP for navigation" instruction and list path + symbol name. Fall back to line range or section only when no clear symbol exists.
- 4-5 questions verifying understanding of the project — pick areas widely (purpose, architecture, conventions, subsystems, abstractions). Avoid clustering around what you touched recently.
- If work is genuinely mid-flight (incomplete, with hidden intent/next-step context), add 1-2 questions about that.
- Finally, one adversarial question: "What alternative approach to the current plan might a fresh reader propose, and what trade-off would it make?" — not to re-decide, but to surface blind spots the current session may have missed.

After drafting, run the self-review gate — it must run in a SEPARATE turn (same-turn review reliably misses noise; the reframing has to land after you already consider the draft done). Arm the Stop-hook guard, send yourself a short reframing prompt, end the turn:

```
flbus listen --arm-only
flbus send --to here:elder --subject quickening-gate --summary "self-review gate" --body-stdin <<'EOF'
The quiz draft is done — now apply the self-review gate checks to it and revise.
EOF
```

The guard blocks the stop and re-prompts deterministically. On that gate wake, consume the message (`flbus take all` — reads the reframing prompt and clears the inbox), then apply these checks to your in-context draft and revise:
- Was this written to make a NEW session understand the project, or is it really this session's work log?
- Count the questions: how many target areas you touched this session vs. project areas you didn't touch? Report both. At most 1 should target touched areas; 0 is fine. Rewrite to broaden if more.
- Did anything brief-but-critical escape capture? Especially: out-of-repo paths (local clones, mounted dirs, fork locations), decisions made verbally with the user, workarounds for issues not in code, external service config not in env files.
- Cut anything source, docs, or git already answer.

Then hand off: make the scion mailbox (`flbus mailbox add scion`), send the revised quiz to scion as the message body (summary `quickening → run answer`), arm the watcher, end the turn.
