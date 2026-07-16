# Wait strategy

Picking the right `wait` form prevents both premature actions (element not ready) and unnecessary delays.

## Decision tree

1. Clicked a link or submitted a form that triggers a full navigation? → `wait load`
2. SPA route change (URL changes but no full reload)? → `wait --url "**/path"`
3. Need a specific element to appear before reading it? → `wait "#sel"` or `wait "#sel:not([hidden])"`
4. Page does async work without DOM hooks you can target? → `wait --text "Success"`
5. Network needs to settle (e.g. analytics, lazy images)? → `wait idle` (heuristic)
6. None of the above fit? → `wait --fn "<JS expression>"` as escape hatch
7. After ANY action, unsure? → `wait idle` is the safest default

## Race-free wait

`wait load` and `wait --url` work via the navigation epoch — captured before the call, satisfied by any subsequent navigation event. Subscribe-before-trigger so a fast load doesn't slip past.

## Timeouts

Default is 30s. Override with `--timeout-ms N`.

```powershell
flmux browser wait load --timeout-ms 60000
```

A timeout becomes `{ok:false, code:"INVALID_VALUE", error:"wait load: timeout after ..."}`. Diagnose with `get url` / `get title` / `snapshot --compact`.

## What `wait idle` actually waits for

`load-finish` followed by 500ms with no new entries appearing in `performance.getEntriesByType("resource")`. This is a heuristic, not true network idle (Stage F skipped real network events). It's adequate for "page seems done loading" but won't wait for delayed WebSocket / EventSource activity. For those, use `wait --fn "..."` against your specific signal.

## Common patterns

### Link click → wait load → read
```powershell
flmux browser click @e1
flmux browser wait load
flmux browser get url
```

### Form submit → wait for result region
```powershell
flmux browser fill @e3 "value"
flmux browser press Enter
flmux browser wait "#result:not([hidden])"
flmux browser get text "#result"
```

### SPA route → wait for new route
```powershell
flmux browser click @e2
flmux browser wait --url "**/dashboard"
flmux browser snapshot
```

### Wait for redirect chain
```powershell
flmux browser click @e1            # → /auth → /redirect → /home
flmux browser wait --url "**/home"
```

### Wait for async error visible
```powershell
flmux browser fill @e3 "bad-value"
flmux browser press Enter
flmux browser wait --text "Invalid input"
```
