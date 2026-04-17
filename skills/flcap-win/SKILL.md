---
name: flcap-win
description: Use to capture a specific visible top-level Windows window to PNG.
shims:
  - target: scripts/capture-window.ps1
    name: flcap
    runner: pwsh
---

# flcap-win

Use `flcap` to capture one specific visible top-level Windows window to PNG.

- Windows only; works with Windows PowerShell 5.1+ and PowerShell 7+.
- Always pass `-Out`.
- Prefer `-Json` for machine-readable results.

## Target selection

Priority:

1. `-Hwnd`
2. `-Pid`
3. `-ProcessName` + `-TitleContains`
4. `-ProcessName`
5. `-TitleContains`

Notes:

- `-Hwnd` accepts decimal or `0x...` hexadecimal text.
- `-ProcessName` ignores an optional `.exe` suffix.
- `-ProcessName` is exact-match by default; `*` and `?` enable wildcard matching.
- If multiple windows match, `flcap` prefers the main window, then the foreground window, then titled windows; otherwise it fails with candidate details.

## Flags

- `-Json`: emit one JSON object on stdout.
- `-ClientOnly`: capture only the client area.
- `-RestoreIfMinimized`: restore a minimized target before capture; otherwise minimized targets fail with code `12`.
- `-Activate`: attempt to bring the target window to the foreground before capture.
- `-NoFallback`: fail instead of using screen-copy fallback.
- `-ScreenCopyOnly`: skip `PrintWindow` and capture via screen copy. Use for GPU-composited content (Chromium browsers, WebGL, hardware-accelerated video) that `PrintWindow` renders as black. Requires the window to be visible and unoccluded — combine with `-Activate`. Mutually exclusive with `-NoFallback`.
- Default capture tries `PrintWindow` first and may fall back to screen copy.

## Output contract

- Success returns `ok`, `method`, `hwnd`, `pid`, `title`, `out`, `width`, `height`.
- Failure returns `ok=false`, `code`, `message`, and sometimes `candidates` or extra details.

## When the `flcap` shim is not available

If `flcap` is not on `PATH` (e.g. shim registration failed or the skill is used outside the harness), call the script directly:

```powershell
pwsh "<skill-dir>/scripts/capture-window.ps1" -Out "$env:TEMP\notepad.png" -ProcessName notepad -Json
```

`<skill-dir>` is the directory containing this SKILL.md. All parameters are identical to the shim.

## Examples

```powershell
flcap -Out "$env:TEMP\notepad.png" -ProcessName notepad -TitleContains "Untitled" -Json
flcap -Out "$env:TEMP\editor.png" -ProcessName 'code*' -TitleContains "main.py" -Json
flcap -Out "$env:TEMP\app.png" -Pid 4242 -RestoreIfMinimized -Activate -Json
flcap -Out "$env:TEMP\client.png" -Hwnd 0x00123456 -ClientOnly -NoFallback -Json
flcap -Out "$env:TEMP\edge.png" -ProcessName msedge -TitleContains "My page" -Activate -ScreenCopyOnly -Json
```
