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
3. error

There is no hidden last-active fallback.

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
