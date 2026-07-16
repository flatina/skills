---
name: flmux-browser-automation
description: Drive flmux browser panes via `flmux browser`. Use this skill whenever the task involves browser automation inside flmux — opening pages, filling forms, clicking, navigating, login flows, scraping page state, verifying UI behavior, or any workflow that touches browser panes, snapshots, refs (`@e1`), or `flmux browser ...` commands.
allowed-tools:
  - Bash(flmux browser *)
  - Bash(flmux get *)
  - Bash(flmux call *)
  - Bash(flmux ls *)
---

# flmux Browser Automation

Automation lives in `flmux browser <op>` over flmux's path layer. Each op resolves to `path.call /panes/{paneId}/browser/{op}`. The agent's job is to compose `open → snapshot → click/fill/wait` loops.

## Golden path

```powershell
flmux browser open https://example.com --json   # creates pane, returns paneId
flmux browser snapshot --pane <id>                # accessibility refs @e1, @e2, ...
flmux browser click @e1 --pane <id>               # click by ref
flmux browser wait load --pane <id>               # wait after nav
flmux browser get text "#result" --pane <id>      # read result
```

Re-`snapshot` after navigation, reload, or any DOM-significant action. Refs are session-local and ephemeral.

## Target forms

`click`, `fill`, `hover`, `focus`, `check`, `uncheck`, `select`, `scroll-to`, `get *`, `is *` accept a `<target>` positional. Forms:

- `@e1` — ref from `snapshot`
- `#id`, `.class`, `div > a` — CSS selector
- `text=Sign in` — visible text on a button/link
- `label=Email` — label text → associated input
- `role=button[name='Submit']` — ARIA role + name
- `testid=foo` — `data-testid` attribute
- `100,200` — viewport coords (CSS px)

Prefer refs after `snapshot`. Use semantic locators (`text=`, `role=`, `label=`) when refs are missing or unstable.

## Pane selection

`--pane <id>` is explicit. Omit → first browser pane found via workspace status. Multiple browser panes → always pass `--pane` to be deterministic. List all browser panes:

```powershell
flmux browser list   # paneId, workspaceId, url
```

## Wait variants

| Form | Use |
|---|---|
| `wait load` | after a click/nav that triggers full navigation |
| `wait idle` | after async fetches — waits for resources to settle |
| `wait "#sel"` | element appears (selector polling) |
| `wait --text "X"` | body innerText contains string |
| `wait --url "**/dashboard"` | URL match (glob) — fires on `navigate` + `load-finish` |
| `wait --fn "expr"` | JS expression becomes truthy |

After form submit that doesn't navigate, use `wait "#result"` or `wait --text "Success"`.

## Common patterns

### Form fill
```powershell
flmux browser snapshot
flmux browser fill @e3 "Jane"
flmux browser fill @e4 "jane@example.com"
flmux browser press Enter
flmux browser wait "#result:not([hidden])"
flmux browser get text "#result"
```

### Login + return
After a click that opens a popup (OAuth/SSO), bunite emits a popup arm and flmux creates a new pane automatically. Find it with `list`, switch via `--pane`. After auth completes (popup may close), return to opener and `snapshot` again.

### Verify navigation
```powershell
flmux browser click @e1
flmux browser wait load
flmux browser get url
flmux browser get title
```

### Inspect state
```powershell
flmux browser is visible "#error-banner"   # → true/false
flmux browser is enabled @e5
flmux browser console list --level error
flmux browser screenshot --out /tmp/page.png
```

## JSON output

`--json` is unnecessary — all `flmux browser` commands print JSON envelopes by default. Parse `value` for results, `error`/`code` for failures.

## Capability gates

Not every backend supports every op. Linux WebKitGTK has no native input; mac WKWebView has no accessibility snapshot, frames, downloads, or popups. Check:

```powershell
flmux browser capabilities
```

Operations that hit a missing capability return `{ok:false, code:"NOT_SUPPORTED", ...}` — fall back to `eval` for read-only work.

## Refs and snapshots

Refs (`@e1`, `@e2`) come from `flmux browser snapshot`. They are:

- session-local (cleared on next snapshot, on full page load, on pane close)
- structurally verified at resolve time (signature mismatch → `stale_ref`)
- frame-scoped (a ref tied to an iframe stays scoped to that frame)

Always re-snapshot after navigation, reload, form submit, or any agent-triggered DOM change. Stale refs throw `stale_ref` — recover by re-snapshotting, not by retrying the old ref.

For ref lifecycle details: `references/snapshot-refs.md`.

## Frames (iframes)

Stripe Elements, embedded checkouts, etc. live in cross-origin iframes. Read DOM from them via:

```powershell
flmux browser eval --frame <frameId> "document.querySelector('input').value"
flmux browser snapshot --frame <frameId>          # if supported
```

`flmux browser list-frames` (when wired) returns frame IDs. Input dispatch (`click`/`type`) inside frames is not yet supported — use the main frame's coord for now.

## Failure recovery

When `stale_ref`: re-`snapshot`, find the new ref.

When `NOT_SUPPORTED`: check `capabilities`, route around (use `eval` for reads).

When pane gone: `list` to confirm, recreate via `open` if needed.

When `wait` times out: print `get url`, `get title`, `snapshot --compact` to diagnose what state the page is in.

For more: `references/troubleshooting.md`.

## References

- `references/commands.md` — full command cheat sheet
- `references/snapshot-refs.md` — refs lifecycle + signature scoring
- `references/wait-strategy.md` — picking the right wait variant
- `references/capability-matrix.md` — backend support table
- `references/troubleshooting.md` — common failures
