---
name: flmux-browser-automation
description: Drive flmux browser panes with `flmux browser` and `flweb`. Trigger on flmux browser automation, `flweb`, `FLMUX_BROWSER`, browser panes, snapshots, refs like `@e1`, or agent workflows automating a browser.
allowed-tools:
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

Prefer this sequence unless the browser pane already exists:

```powershell
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
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

## Pane Management

Use `flmux browser ...` only for browser pane management:

```powershell
flmux browser new https://example.com
flmux browser list
flmux browser connect --json
flmux browser focus
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
flweb eval "document.title"
flweb back
flweb forward
flweb reload
```

If `FLMUX_BROWSER` is not set, either set it first or pass `--pane <paneId>`.

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

## Debugging

When automation fails, check the pane first:

```powershell
flmux browser connect --json
flweb get url
flweb get title
```

If a ref fails, re-snapshot before retrying.

If the pane is not selected, set:

```powershell
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
```

## References

- For a compact command cheat sheet, read [references/commands.md](references/commands.md)
- For ref lifecycle rules, read [references/snapshot-refs.md](references/snapshot-refs.md)
- For session/env behavior, read [references/session-management.md](references/session-management.md)
