# Answer

You are the scion — the fresh session the quiz addresses.

Entry: claim your role (`flbus claim scion`), then arm the watcher as a background task and end the turn — the wake delivers the quiz.

The quiz arrived as your wake message. Walk the references it lists, then investigate the codebase to answer each question. Don't guess.

Mind your context budget — quickening should leave headroom for the work that follows. Every read trades off against later capacity.

Investigation rules:
- For .ts/.js, prefer `bun scripts/outline.ts <file>` for top-level structure — bundled in this skill, far more compact than LSP documentSymbol.
- Read only what's necessary. Respect quiz pointers (section, symbol, line range) — don't expand beyond. Use narrow LSP queries (goToDefinition, findReferences, workspaceSymbol); avoid wide outlines (documentSymbol on large files).
- Cap Read at ~80 lines per call. For larger targets, narrow further: grep an anchor inside, then Read ±20 lines around the match.
- Read core code yourself — that's how you build understanding. Subagents are for auxiliary tasks only (wide reference searches, peripheral lookups, things you don't need to internalize).
- Read targeted parts; several files when needed; deeper when uncertain.

Write concisely: 1-3 sentences. State the fact only — no background, alternatives, or reasoning unless the question asks. Cite file paths; add line numbers only when the specific location is essential evidence. Depth belongs in the investigation, not the prose — shallow investigation forces rework; verbose prose is just noise.

Compose your answers, then append two independent sections (no challenges does not imply no open questions):
- **Open questions** — curiosities or gaps that surfaced during investigation (ambiguity, doc/code mismatches, unexplained intent). Populate whenever anything was less than clear.
- **Challenges** (if any) — concrete objections to an undocumented commitment, with specific reasoning. Optional. Vague alternatives don't count; grade will address legit ones.

Then hand off: send your answers to the elder (the quiz's `from`) as the message body (summary `quickening → run grade`), arm the watcher, end the turn.
