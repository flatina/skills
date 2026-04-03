# Session and Environment

## Core Variables

### `FLMUX_BROWSER`

The active browser pane for `flweb`.

Typical setup:

```powershell
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
```

All hot-path commands use this unless `--pane` is passed.

### `FLMUX_APP_IPC`

The app RPC endpoint for the running flmux session.

Inside a flmux terminal, this is usually already set.

Outside flmux, you may need `--session` when the session cannot be resolved automatically.

## Pane Selection

`flweb` resolves the target browser pane in this order:

1. `--pane <paneId>`
2. `FLMUX_BROWSER`
3. Active browser pane (if the currently focused pane is a browser)
4. Most recently activated browser pane (lowest age)
5. Only browser pane (if exactly one exists)
6. Error (multiple panes, none active)

Inside a flmux terminal, you often don't need `FLMUX_BROWSER` at all — if you just opened a browser pane, it's the most recent and will be selected automatically.

## Useful Patterns

### Fresh Pane

```powershell
$env:FLMUX_BROWSER = (flmux browser new https://example.com)
flmux browser connect
flweb snapshot --compact
```

### Reattach to Existing Pane

```powershell
flmux browser list
$env:FLMUX_BROWSER = "browser.1234abcd"
flmux browser connect
```

### Explicit Override

```powershell
flweb get url --pane browser.1234abcd
```

## Debugging

When the pane selection is unclear:

```powershell
flmux browser list
flmux browser connect --json
flweb get url
```

If `FLMUX_BROWSER` is missing, set it again instead of expecting `flweb` to guess.
