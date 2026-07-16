# Capability matrix

Browser pane backends differ in what they support. Run `flmux browser capabilities` to see the live flags.

| Capability | Win WebView2 | Win CEF | mac WKWebView | linux WebKitGTK |
|---|---|---|---|---|
| `evaluate` | ✔ | ✔ | ✔ | ✔ |
| `surfaceEvents` (navigate / load / title) | ✔ | ✔ | ✔ | ✔ |
| `screenshot` | ✔ | ✔ | ✔ | ✔ |
| `click` / `type` / `press` / `mouse` (native, trusted) | ✔ | ✔ | ✔ | ✘ |
| `scroll` | ✔ | ✔ | ✔ | ✘ |
| `dialogs` (alert / confirm / prompt) | ✔ | ✔ | ✔ | ✔ |
| `console` (page log capture) | ✔ | ✔ | ✔ | ✔ |
| `accessibilitySnapshot` | ✔ | ✔ | ✘ | ✘ |
| `getBoundingRect` | ✔ | ✔ | ✔ | ✔ |
| `frames` (`listFrames` + frame-scoped eval) | ✔ | ✔ | ✘ | ✘ |
| `downloads` | ✔ | ✔ | ✘ | ✘ |
| `popups` (`window.open`, `target="_blank"`) | ✔ | ✔ | ✘ | ✘ |

## Fallback strategies

### `accessibilitySnapshot` missing (mac, linux)
`flmux browser snapshot` falls back to a JS DOM walk. Refs work but with weaker role/name resolution. Prefer CSS selectors or `testid=` on these backends.

### Native input missing (linux)
`click` / `type` / `press` / `scroll` / `mouse` return `{ok:false, code:"NOT_SUPPORTED"}`. Workaround: dispatch synthetic events via `eval`:
```powershell
flmux browser eval "document.querySelector('#submit').click()"
```
Synthetic events have `isTrusted: false`; some anti-bot pages reject them.

### `frames` missing (mac, linux)
Cross-origin iframe DOM is unreachable from `eval`. flmux returns `{ok:false, code:"cross_origin"}`. No workaround on these backends today.

### `downloads` missing (mac, linux)
`waitForDownload` returns `{ok:false, code:"not_supported"}`. Page-triggered downloads either save via the browser's default UI or are dropped, depending on backend.

### `popups` missing (mac, linux)
`window.open` and `target="_blank"` clicks do not produce flmux panes. The popup either opens externally or is suppressed. Workaround: open the URL directly via `flmux browser open <popup-url>`.

## Console capture on external origins

The `console` stream relies on a preload script bunite injects into pages it serves (appres origins). Pages on external origins (`https://example.com` etc.) have no preload → `console list` returns empty. This is a fundamental limitation of the preload-based approach.

For external sites, capture errors via:
```powershell
flmux browser eval "window.__errors = window.__errors || []; window.addEventListener('error', e => window.__errors.push(e.message)); true"
# do work
flmux browser eval "window.__errors"
```
