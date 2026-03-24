# Snapshot and Refs

Refs like `@e1`, `@e2`, and `@e3` come from `flweb snapshot`.

## Core Rule

Treat refs as valid only for the current page state.

Re-run `flweb snapshot` after:

- navigation
- reload
- form submission
- clicking something that changes the DOM
- any action where you are not sure the old elements still exist

## Typical Flow

```powershell
flweb snapshot --compact
flweb click @e1
flweb wait load
flweb snapshot --compact
```

## Why This Matters

`flweb snapshot` stamps the current page DOM with transient `data-flmux-ref="eN"` attributes.

That means:

- refs are tied to the current DOM
- a fresh snapshot rewrites the ref set
- navigation or re-rendering can invalidate old refs immediately

## Good Patterns

```powershell
flweb snapshot --compact
flweb fill @e3 "Jane"
flweb fill @e4 "jane@example.com"
flweb press Enter
flweb wait "#result:not([hidden])"
flweb get text #result
```

```powershell
flweb snapshot --compact
flweb click @e1
flweb wait load
flweb snapshot --compact
flweb click @e2
```

## Failure Recovery

If a ref fails:

1. run `flweb snapshot --compact` again
2. inspect the new refs
3. retry with the new ref

Do not keep retrying the same stale ref.
