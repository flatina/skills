# Answer

The quiz was written by a prior session; you are the "next session" it addresses.

Read `.tmp/quickening-1-elder-quiz.md`. Walk the listed references next, then investigate the codebase to answer each question. Don't guess.

Mind your context budget — quickening should leave headroom for the work that follows. Every read trades off against later capacity.

Investigation rules:
- For .ts/.js, prefer `bun scripts/outline.ts <file>` for top-level structure — bundled in this skill, far more compact than LSP documentSymbol.
- Read only what's necessary. Respect quiz pointers (section, symbol, line range) — don't expand beyond. Use narrow LSP queries (goToDefinition, findReferences, workspaceSymbol); avoid wide outlines (documentSymbol on large files).
- Cap Read at ~80 lines per call. For larger targets, narrow further: grep an anchor inside, then Read ±20 lines around the match.
- Read core code yourself — that's how you build understanding. Subagents are for auxiliary tasks only (wide reference searches, peripheral lookups, things you don't need to internalize).
- Read targeted parts; several files when needed; deeper when uncertain.

Write concisely: 1-3 sentences. State the fact only — no background, alternatives, or reasoning unless the question asks. Cite file paths; add line numbers only when the specific location is essential evidence. Depth belongs in the investigation, not the prose — shallow investigation forces rework; verbose prose is just noise.

Save answers to `.tmp/quickening-2-scion-answer.md`. After answering, append any open questions that came up during investigation.

To challenge an undocumented commitment, don't argue it in your answers — append it to open questions with concrete reasoning (new evidence, missed constraint, specific failure case). Vague alternatives don't count; grade will address legit ones.

