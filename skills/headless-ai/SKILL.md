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

### Claude CLI

`claude -p` writes the agent's response to stdout. Redirect to a file:

```bash
claude -p --dangerously-skip-permissions "Review src/auth/ for bugs and risks" > .tmp/<output>.md
```

### Codex CLI

Use `-o/--output-last-message` to have codex write the final message to a file directly. Discard stdout (execution logs only). Add `--ephemeral` so the one-shot run doesn't leave session files on disk.

**Always close codex's stdin** — when launched from a non-interactive shell (like Claude Code's Bash tool), stdin is a pipe with no EOF, so codex blocks on `read_to_end` and hangs indefinitely. Pipe a prompt in, redirect a file, or attach `</dev/null` for argv-only invocations.

Single-line prompt via argv (note `</dev/null`):

```bash
codex exec --yolo --ephemeral -o .tmp/<output>.md "Review src/auth/ for bugs and risks" </dev/null 2>/dev/null >/dev/null
```

Multi-line prompt via heredoc-stdin (the heredoc itself supplies EOF):

```bash
cat <<'PROMPT' | codex exec --yolo --ephemeral -o .tmp/<output>.md 2>/dev/null >/dev/null
<prompt body here>
PROMPT
```

For code review against git state, prefer the built-in subcommand — it handles diff scoping for you (still close stdin):

```bash
codex exec --ephemeral review --uncommitted -o .tmp/<output>.md </dev/null 2>/dev/null >/dev/null
# or: --base main, --commit <sha>
```

Then read the result file with the Read tool.

If the user doesn't specify which CLI, pick whichever fits the task — both work for general delegation.

## Execution

Headless CLI execution can take a long time. Set a long timeout or remove it entirely to prevent the process from being killed mid-run.

## Prompt construction

Be specific about the target path and scope.

Tell the delegated agent who its reader is. The reader is another AI agent that already has full context on the code or plan being reviewed — not a human seeing it fresh. Include this in the prompt, e.g. *"Your output goes to another AI agent with full context. Be concise — no preamble, no restating the code, no explaining basics."*

Avoid words that bias toward exhaustive output ("thorough", "comprehensive", "covering all of X, Y, Z"). State the goal and let the agent decide what's worth reporting. A reviewer that finds nothing worth flagging should be free to say so.

Frame the deliverable around *signal* rather than *coverage* — what would actually change the orchestrator's next action. Don't prescribe section counts, severity tags, or formatting; the agent's judgment is the reason you delegated.
