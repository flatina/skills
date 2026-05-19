---
name: headless-ai
description: Delegate tasks to an independent AI agent via headless CLI (`claude -p` or `codex exec`), then review the results and apply feedback. Use when the user explicitly asks to delegate a review, analysis, or task to another agent — e.g., "headless로 리뷰 돌려", "다른 에이전트한테 리뷰 맡겨", "claude/codex로 검토하고 반영해줘".
---

# Headless AI

Delegate a task to an independent AI agent, review the output, and apply improvements — all automatically.

## Workflow

1. Run headless CLI with the user's task, capturing the result to a file
2. Read the result file (selectively if it's long — pull only the sections you need)
3. Act on it: apply changes for a review/task, or use the findings for an analysis/research request. Don't accept suggestions blindly — the delegated agent may be wrong about your codebase; weigh each point against what you can see directly
4. Report the outcome — summarize, don't dump the file contents back into the final response
5. Delete the result file

## Commands

Write outputs under a gitignored scratch directory like `.tmp/` (project-local) or the system temp dir — never directly into source folders, or review files will accumulate next to the code. Examples below use `.tmp/<output>.md`.

If the user doesn't specify which CLI, pick whichever fits the task — both work for general delegation.

### Claude CLI

`claude -p` writes the agent's response to stdout. Redirect to a file:

```bash
claude -p --dangerously-skip-permissions "Review src/auth/ for bugs and risks" > .tmp/<output>.md
```

### Codex CLI

`codex exec` writes its final message to a file via `-o`. Discard execution logs from stdout, and use `--ephemeral` so the one-shot leaves no session files.

**Codex's stdin must EOF** — use a heredoc, file redirect, or `</dev/null`. Otherwise the open pipe never closes and codex hangs.

```bash
# Single-line prompt
codex exec --yolo --ephemeral -o .tmp/<output>.md "Review src/auth/ for bugs and risks" </dev/null 2>/dev/null >/dev/null

# Multi-line prompt
cat <<'PROMPT' | codex exec --yolo --ephemeral -o .tmp/<output>.md 2>/dev/null >/dev/null
<prompt body here>
PROMPT

# Code review against git state — handles diff scoping
codex exec --ephemeral review --uncommitted -o .tmp/<output>.md </dev/null 2>/dev/null >/dev/null
# or: --base main, --commit <sha>
```

## Execution

Headless CLI execution can take a long time. Set a long timeout or remove it entirely to prevent the process from being killed mid-run.

## Prompt construction

- Tell the delegate its reader is another AI agent with full context — *"Be concise — no preamble, no restating the code, no explaining basics."*
- Frame the deliverable around *signal*, not *coverage*. Avoid bias words ("thorough", "comprehensive", "all of X, Y, Z"); let the agent judge what's worth reporting, and let it say "nothing to flag."
- For review/diagnosis, ask for findings only — *"name the file:line and the issue; no patches, fix snippets, or rewritten code."* The orchestrator applies fixes.
