# Quiz

First, remove any existing `.tmp/quickening-*.md` files from prior runs.

This is for the next session's understanding of the project — not a log of what you did this session. Skip anything derivable from source, docs, or git; the next session can re-investigate. Most questions should test understanding outside the area of recent work — if your session's work is complete, that work is now just a small fraction of the project and shouldn't dominate the quiz. Each question should ask about one thing only — don't mix past, present, and next steps in a single question.

Save to `.tmp/quickening-1-elder-quiz.md`:
- Undocumented commitments (if any) — constraints the next session must respect that aren't yet in source or docs. One line each. If it matters long-term, also document it in the project itself. Examples: "user deferred legacy table migration to next sprint", "approach A for now; B prototyped on branch xyz pending review". Don't re-litigate in answers — raise concrete counter-evidence via an open question instead.
- Operating guidance (if any) follows in the same format: rules about how to work, e.g. style, process, principles. Examples: "terse responses, no trailing summaries", "ask before committing", "implement simple structures concisely — no premature abstraction".
- Brief context — only what the next session needs.
- References the next session should read — small critical docs in full; add scope hints (function name, line range, section) only for large files
- 4-5 questions verifying understanding of the project — pick areas widely (purpose, architecture, conventions, subsystems, abstractions). Avoid clustering around what you touched recently.
- If work is genuinely mid-flight (incomplete, with hidden intent/next-step context), add 1-2 questions about that.
- Finally, one adversarial question: "What alternative approach to the current plan might a fresh reader propose, and what trade-off would it make?" — not to re-decide, but to surface blind spots the current session may have missed.

After drafting, review once: is every item for the next session's project understanding, not a log of what you did? Rewrite anything that fails.