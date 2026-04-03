---
name: flmux-browser-automation
description: Drive flmux browser panes with `flmux browser` and `flweb`. Use this skill whenever the task involves browser automation inside flmux — opening web pages, filling forms, clicking buttons, navigating sites, login/auth flows, testing web UI, scraping page content, verifying page state, or any workflow that touches `flweb`, `FLMUX_BROWSER`, browser panes, snapshots, or refs like `@e1`.
allowed-tools:
  - Bash(flmux summary *)
  - Bash(flmux browser *)
  - Bash(flweb *)
---

# flmux Browser Automation

## Overview

Use this skill when browser automation should happen inside flmux rather than through a standalone browser tool. The core model is:

1. Create or pick a flmux browser pane
2. Resolve that pane through `FLMUX_BROWSER` or `--pane`
3. Use `flweb` for hot-path automation
4. Re-run `flweb snapshot` after page changes before using refs again

## Core Workflow

Start by discovering the running flmux session:

```powershell
flmux summary --json
```

This returns the web server URL, existing panes, and session state. Use `webServerUrl` for internal pages.

Then create or pick a browser pane:

```powershell
$env:FLMUX_BROWSER = (flmux browser new http://127.0.0.1:3000/about)
flmux browser connect
flweb snapshot --compact
```

Then interact with the page:

```powershell
flweb click @e1
flweb wait load
flweb get url
```

If the task is already running inside a flmux terminal, `FLMUX_APP_IPC` resolves the session automatically. Outside flmux, pass `--session` to `flmux browser ...` and `flweb ...` if needed.

`FLMUX_BROWSER` is optional when only one browser pane exists or when a browser pane is active — `flweb` auto-targets the active or most recently activated browser pane. Set `FLMUX_BROWSER` explicitly when multiple browser panes exist and you need a specific one.

## Target Forms

Supported target forms:

- ref: `@e1`
- CSS selector: `#result`
- text locator: `text=Focus Name`
- label locator: `label=Email`
- role locator: `role=button[name='Reveal Result']`

Prefer refs after `flweb snapshot`. Use semantic locators when refs are not available yet or when a more stable human-readable selector is clearer.

## Pane Management

Use `flmux browser ...` only for browser pane management:

```powershell
flmux browser new https://example.com
flmux browser list
flmux browser connect --json
flmux browser focus             # bring the pane into view (activate its tab)
flmux browser close
```

Default command output is concise text. Use `--json` when structured output is helpful.

## Common Patterns

### Create a Fresh Browser Pane

```powershell
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
flmux browser connect
flweb snapshot --compact
```

Use this when the task should start from a clean page in a fresh browser pane.

### Reuse an Existing Browser Pane

```powershell
flmux browser list
$env:FLMUX_BROWSER = "browser.1234abcd"
flmux browser connect
flweb get url
```

Use this when the browser pane already exists and the task should continue from the current page state.

### Form Interaction

```powershell
flweb snapshot --compact
flweb fill @e3 "Jane"
flweb fill @e4 "jane@example.com"
flweb press Enter
flweb wait "#result:not([hidden])"
flweb get text #result
```

Use refs immediately after a snapshot. If the DOM changes, re-run `snapshot` before using refs again.

### Navigation and Verification

```powershell
flweb click @e1
flweb wait load
flweb get url
flweb get title
```

Use this after any click or action that can trigger navigation.

### Login / Auth Popup

Many sites open login in a new tab or popup. The flow is: click login → detect new tab → switch → authenticate → return.

```powershell
# On the original page
flweb snapshot --compact
flweb click --json @e5                    # login button — may open new tab
# Check JSON output for newPanes

# Switch to the popup tab
$env:FLMUX_BROWSER = "browser.newPaneId"  # from newPanes[0].paneId
flweb wait load
flweb snapshot --compact
flweb fill @e2 "user@example.com"
flweb fill @e3 "password"
flweb click @e4                           # submit
flweb wait load

# Return to original tab
$env:FLMUX_BROWSER = "browser.originalId"
flweb wait idle
flweb snapshot --compact                  # verify logged-in state
```

The popup tab may close itself after login completes. If it does, you only need to switch `FLMUX_BROWSER` back and re-snapshot the original page.

## Wait Strategy

Choosing the right `wait` form prevents both premature actions (element not ready) and unnecessary delays (waiting for things that already happened).

| Form | When to use |
|------|-------------|
| `wait load` | After click/navigate that triggers a full page navigation (URL changes) |
| `wait idle` | After actions that trigger async fetches — waits for network to settle |
| `wait "#selector"` | When you need a specific element to appear before interacting (e.g. `wait "#result:not([hidden])"`) |
| `wait --text "Success"` | When the signal is visible text, not a DOM element |
| `wait --url "**/dashboard"` | When a redirect chain must finish before proceeding |
| `wait --fn "expr"` | Escape hatch — use a JS expression when none of the above fits |

Rules of thumb:
- After a link click or `navigate`: `wait load`
- After a form submit that shows results without navigating: `wait idle` or `wait "#result"`
- After a JS-heavy SPA transition: `wait idle` then `wait` for the expected element
- If unsure: `wait idle` is the safest default after any action

## flweb Commands

Hot-path commands:

```powershell
flweb snapshot --compact
flweb navigate https://example.com/docs
flweb click @e1
flweb fill @e3 "hello"
flweb press Enter
flweb wait load
flweb wait idle
flweb wait "#result:not([hidden])"
flweb wait --text "Success"
flweb wait --url "**/dashboard"
flweb wait --fn "document.readyState === 'complete'"
flweb get url
flweb get title
flweb get text @e1
flweb get html #result
flweb get value @e3
flweb get attr @e4 placeholder
flweb get box @e3                                       # bounding rect — useful for verifying visibility/position
flweb eval "document.title"
flweb back
flweb forward
flweb reload
```

If `FLMUX_BROWSER` is not set, either set it first or pass `--pane <paneId>`.

## JSON Output

Use `--json` when another tool or agent needs structured output.

Examples:

```powershell
flmux browser connect --json
flweb snapshot --json
flweb get box @e3 --json
flweb eval "document.title" --json
```

Prefer default terse text when composing quick shell pipelines by hand. Prefer `--json` when the caller will parse the response.

## New Tab Detection

When `click` or `eval` opens a new tab (e.g. `target="_blank"` link), the `--json` output includes a `newPanes` array:

```powershell
flweb click --json @e1
# {"ok":true,"paneId":"browser.abc","newPanes":[{"paneId":"browser.def","url":"...","opener":"browser.abc"}]}
```

To interact with the new tab, switch `FLMUX_BROWSER`:

```powershell
$result = flweb click --json @e1 | ConvertFrom-Json
if ($result.newPanes) {
  $env:FLMUX_BROWSER = $result.newPanes[0].paneId
  flweb wait load
  flweb snapshot --compact
}
```

`browser list` shows all browser panes with AGE (activation recency) and OPENER (which pane opened it):

```powershell
flmux browser list
```

## Snapshots

`--compact` (default for automation) shows interactive elements (links, buttons, inputs) with their refs — enough to decide what to click or fill. Use the full snapshot (no `--compact`) when you need surrounding text content, headings, or non-interactive elements to understand the page structure.

In practice, always start with `--compact`. Switch to full only when `--compact` doesn't show the information you need.

## Refs

Refs like `@e1` come from `flweb snapshot`. They are only valid for the current page state.

Always re-run `snapshot` after:

- navigation
- reload
- clicking something that changes the DOM significantly
- form submission
- tab/pane switching that may have re-rendered the page

Do not assume old refs survive a page change.

For more detail, read [references/snapshot-refs.md](references/snapshot-refs.md).

## Session and Environment

- `FLMUX_BROWSER` selects the current browser pane for `flweb`
- `FLMUX_APP_IPC` lets CLI commands talk to the running flmux session
- inside a flmux terminal, `FLMUX_APP_IPC` is usually already available
- outside flmux, use `--session` when the session cannot be resolved automatically

For more detail, read [references/session-management.md](references/session-management.md).

## Debugging and Error Recovery

When automation fails, diagnose before retrying.

### Stale ref

A ref like `@e3` no longer exists in the DOM — the page changed since the last snapshot.

```powershell
flweb snapshot --compact       # get fresh refs
# find the new ref for the element you need, then retry
```

### Pane gone or disconnected

The browser pane was closed or the connection dropped.

```powershell
flmux browser list             # is the pane still alive?
flmux browser connect --json   # reconnect and check state
```

If the pane is gone, create a new one and start over.

### Page load failure or timeout

The page didn't finish loading, or a wait timed out.

```powershell
flweb get url                  # confirm where we are
flweb get title                # blank title often means error page
flweb reload                   # retry the load
flweb wait load
```

### Wrong page / unexpected state

After an action the page isn't where you expected.

```powershell
flweb get url
flweb snapshot --compact       # see what's actually on screen
```

Read the snapshot output and decide whether to navigate back, retry the action, or adjust the approach. Do not blindly repeat the same action.

## References

- For a compact command cheat sheet, read [references/commands.md](references/commands.md)
- For ref lifecycle rules, read [references/snapshot-refs.md](references/snapshot-refs.md)
- For session/env behavior, read [references/session-management.md](references/session-management.md)
