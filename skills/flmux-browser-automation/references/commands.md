# flmux Browser Automation Commands

## Setup

```powershell
flmux summary --json          # discover webServerUrl, existing panes
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
flmux browser connect
```

## Pane Management

```powershell
flmux browser new https://example.com
flmux browser list
flmux browser connect --json
flmux browser focus                       # activate the pane's tab
flmux browser close
```

## Snapshot and Navigation

```powershell
flweb snapshot --compact
flweb navigate https://example.com/docs
flweb back
flweb forward
flweb reload
flweb wait load
flweb wait idle
flweb wait "#result:not([hidden])"
flweb wait --text "Success"
flweb wait --url "**/dashboard"
flweb wait --fn "document.readyState === 'complete'"
```

## Interaction

```powershell
flweb click @e1
flweb fill @e3 "hello"
flweb fill "label=Email" "user@example.com"
flweb click "text=Focus Name"
flweb get text "role=button[name='Reveal Result']"
flweb press Enter
```

## Read Values

```powershell
flweb get url
flweb get title
flweb get text @e1
flweb get html #result
flweb get value @e3
flweb get attr @e4 placeholder
flweb get box @e3                         # bounding rect (visibility/position check)
flweb eval "document.title"
```

## Practical Workflow

```powershell
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
flmux browser connect
flweb snapshot --compact
flweb click @e1
flweb wait load
flweb snapshot --compact
```

## New Tab Detection

```powershell
flweb click --json @e1        # newPanes in JSON output if a new tab opened
flweb eval --json "window.open('https://example.com')"
flmux browser list            # AGE, OPENER columns
```

## Practical Rules

- Use `flmux browser ...` for pane management.
- Use `flweb ...` for page automation.
- Re-run `flweb snapshot` after page changes before reusing refs.
- Use `--json` when structured output is easier to consume.
- Supported target forms: `@e1`, CSS selectors, `text=...`, `label=...`, `role=...`.
