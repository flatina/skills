# Generate

First, remove any existing `.tmp/quickening-*.md` files from prior runs.

Write questions that verify understanding of this project — from overall concept and architecture down to current work state. Each question should ask about one thing only — don't mix past, present, and next steps in a single question.

Save to `.tmp/quickening-quiz.md`:
- A one-line header identifying this as a quiz from the prior session to the next session
- Settled decisions (if any) go right after the header, terse one-line-each, self-contained — conclusion first, with a brief clause if useful. Examples: "terminal API: single channel over multi-session — simpler back-pressure", "no v1 compat shim — migration window closed", "no common factory extraction". Don't re-litigate in answers — raise concrete counter-evidence via an open question instead.
- Operating guidance (if any) follows in the same format: rules about how to work, e.g. style, process, principles. Examples: "terse responses, no trailing summaries", "ask before committing", "implement simple structures concisely — no premature abstraction".
- Brief context not already captured in project docs — only what the next session needs
- References the next session should read — note relevant scope when a file is large (e.g. function name, line range, section)
- 2-3 broad questions first (e.g. project purpose, concept, key docs)
- Then 1-2 questions on the area/subsystem the current work touches
- Then 2-4 questions about current work (state, intent, next steps)
- Finally, one adversarial question: "What alternative approach to the current plan might a fresh reader propose, and what trade-off would it make?" — not to re-decide, but to surface blind spots the current session may have missed.