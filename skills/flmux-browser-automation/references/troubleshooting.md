# Troubleshooting

## `stale_ref`

The page changed since the snapshot — re-`snapshot` and find the new ref. Do not retry the same ref.

```powershell
flmux browser snapshot
# read the new refs in the output, then retry with the correct one
```

## `NOT_SUPPORTED`

Backend doesn't support this op. Run `flmux browser capabilities` to see what's available, then use a fallback per `references/capability-matrix.md`. Common cases:

- `accessibilitySnapshot` not supported (mac/linux): refs still work via DOM-walk fallback; prefer CSS selectors.
- `frames` not supported (mac/linux): cross-origin iframe DOM unreachable.
- `downloads` not supported (mac/linux): no download tracking.

## Wait timeout

The page didn't reach the awaited state in time. Diagnose:

```powershell
flmux browser get url        # where are we
flmux browser get title      # blank often = error page
flmux browser snapshot       # what's actually on screen
flmux browser console list --level error
```

Decide: navigate back, retry, change strategy. Don't blindly re-run the same `wait`.

## Pane not found / closed

`flmux browser list` to check. If the pane is gone, recreate:

```powershell
flmux browser open <url>
```

If you have the paneId but ops fail with `NOT_FOUND`, the pane was likely closed mid-flow.

## Click does nothing / wrong element

Possible causes:
- Stale ref pointing at a different element after DOM reconcile → re-`snapshot`
- Element is covered by an overlay → check with `get box <target>` for position
- Coords from `get box` outside viewport → scroll-to first: `flmux browser scroll-to @e1`
- Synthetic event blocked by anti-bot (linux + eval fallback only)

## Popup didn't appear

OAuth/SSO often opens in a new tab. flmux auto-creates a pane on `window.open` / `target="_blank"` clicks (on supported backends). Find it:

```powershell
flmux browser list
```

If no new pane: capability `popups` may be false (mac/linux). Open the popup URL directly via `flmux browser open <url>` instead.

## Dialog stuck

`alert` / `confirm` / `prompt` block page execution until you respond. After a click that may trigger a dialog:

```powershell
flmux browser dialog accept    # or `dismiss`
```

If `dialog accept` says "no pending dialog", either it auto-dismissed (5s default timeout) or it never appeared. Check `console errors` for evidence.

## Console buffer empty on external sites

Bunite's console capture relies on a preload script that only injects into appres origins. External pages (`https://example.com` etc.) have no preload → buffer stays empty. Workaround inline:

```powershell
flmux browser eval "window.__errors = []; window.addEventListener('error', e => window.__errors.push(e.message)); true"
# do work
flmux browser eval "JSON.stringify(window.__errors)"
```

## Same-element click toggles wrong state

`check` / `uncheck` read state first via `is checked` and only click if state differs. If the check still goes wrong direction, the page's `aria-checked` may be lying or the click target is the label, not the input. Use `find label "..."` then click that ref instead.

## CEF press DOM `code` mismatch

Known bunite issue (CEF backend only). `KeyboardEvent.key` is correct; `KeyboardEvent.code` may be wrong (e.g. `code === "Equal"` for VK_RETURN). If your page condition depends on `event.code`, prefer key dispatch via `eval` or use `WebView2` engine (`BUNITE_ENGINE=webview2`).

## Linux scroll has no effect

`SendMouseWheelEvent` and friends are not wired on WebKitGTK. Use `eval` fallback:

```powershell
flmux browser eval "window.scrollBy(0, 500)"
```

## Click inside iframe — supported via `resolveAndClick`

Cross-origin iframe (Stripe Elements, OAuth payment frames) input is wired through bunite's atomic `resolveAndClick`, including coord translation. Use `click @e1` or `click "#sel"` against a ref/selector inside the iframe — the trip goes through CDP (`isTrusted` per-call: WebView2 `true`, CEF `false`, mac unsupported).

Limits:
- Transformed iframes (CSS `rotate/skew/scale`) return `not_supported` — axis-aligned only.
- Nested OOPIF (iframe inside iframe inside …) — single layer only.
- mac WKWebView: `frameId` itself is `not_supported` — use main-frame ops or skip.

Old `getBoundingRect({frameId}) → click(x,y)` pattern still returns frame-local coords; don't synthesize page coords manually. Use the high-level `click <target>` instead.

