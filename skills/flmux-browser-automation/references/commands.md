# flmux browser — command cheat sheet

All commands accept `--pane <id>` (defaults to first browser pane found).

## Pane management

```powershell
flmux browser open <url>                      # create or navigate
flmux browser navigate <url>                  # navigate existing
flmux browser list                            # all browser panes
flmux browser focus-pane --pane <id>          # activate
flmux browser close-pane --pane <id>          # close
flmux browser back                            # history back
flmux browser reload
```

## Discovery

```powershell
flmux browser snapshot                        # ax refs (@e1, @e2, ...)
flmux browser find role button                # value=Submit / by=role
flmux browser find text "Sign in"
flmux browser find label "Email"
flmux browser find testid email-input
flmux browser capabilities                    # backend feature flags
```

## Interaction (target = ref | CSS | text= | label= | role= | testid= | x,y)

```powershell
flmux browser click @e1
flmux browser click "text=Submit"
flmux browser click "role=button[name='Save']"
flmux browser click "150,300"                 # viewport coords
flmux browser click @e1 --button right --clicks 2 --modifiers ctrl,shift
flmux browser dblclick @e1
flmux browser hover @e1
flmux browser focus @e3
flmux browser fill @e3 "hello"                # clear + type
flmux browser fill @e3 ""                     # clear only
flmux browser type "free text"                # type at current focus
flmux browser press Enter
flmux browser press a --modifiers ctrl        # ctrl+a
flmux browser check @e5
flmux browser uncheck @e5
flmux browser select @e6 "option-value"
flmux browser scroll-to @e1
flmux browser scroll 0 500                    # wheel scroll dx dy
flmux browser highlight @e1 --duration-ms 2000
```

## Read state

```powershell
flmux browser get url
flmux browser get title
flmux browser get text @e1
flmux browser get text "#result"
flmux browser get html @e1
flmux browser get value @e3
flmux browser get attr @e4 placeholder
flmux browser get box @e3                     # x/y/width/height + visible
flmux browser get count ".item"               # matching element count
flmux browser is visible @e1
flmux browser is enabled @e1
flmux browser is checked @e5
flmux browser eval "document.title"           # generic JS eval
```

## Wait

```powershell
flmux browser wait load                       # full navigation
flmux browser wait idle                       # network idle (heuristic)
flmux browser wait "#sel:not([hidden])"       # selector becomes present
flmux browser wait --text "Success"
flmux browser wait --url "**/dashboard"
flmux browser wait --fn "document.readyState === 'complete'"
flmux browser wait --timeout-ms 60000 load
```

## Dialog / Console

```powershell
flmux browser dialog accept                   # current alert/confirm/prompt
flmux browser dialog accept "prompt response"
flmux browser dialog dismiss
flmux browser console list                    # all log entries
flmux browser console list --level error --clear
flmux browser errors                          # console level=error shortcut
```

## Screenshot

```powershell
flmux browser screenshot --out /tmp/page.png
flmux browser screenshot --format jpeg --quality 80 --out /tmp/page.jpg
```

## Path call escape

Any agent op is also reachable via path:

```powershell
flmux call /panes/<id>/browser/snapshot
flmux call /panes/<id>/browser/click target=@e1
flmux get /status/panes/<id>/browser
```
