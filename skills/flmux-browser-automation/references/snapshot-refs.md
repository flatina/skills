# Snapshots and Refs

`flmux browser snapshot` walks the page's interactive DOM and returns an array of refs:

```json
{
  "generation": 3,
  "url": "https://example.com",
  "refs": [
    { "ref": "@e1", "role": "button", "name": "Submit", "rect": {"x":..., "y":..., "width":..., "height":...} },
    { "ref": "@e2", "role": "textbox", "name": "Email", "type": "email", "rect": {...} }
  ]
}
```

## Invalidation

Refs go stale when:

- A new `snapshot` runs (generation bumps; old refs are gone)
- The page reaches `load-finish` for a new navigation (registry cleared)
- The element is removed or replaced (signature mismatch on resolve)

Refs DO survive:

- DOM mutations that don't replace the element (text update, attribute change)
- `history.pushState` (soft invalidate — resolve still works if the element is still there)

## Signature scoring

A ref's signature combines:

- `role` + `name` (medium weight)
- `id`, `ancestorIdHint` (strong weight — `data-testid`, `aria-rowindex`, `data-key`, parent id)
- `textHash`, `domOrderKey` (weak weight)

On resolve, the live element's signature is recomputed and scored against the stored one. Score ≥ 5 = match. Below threshold → `stale_ref`.

This means:

- React list reconciliation that reuses DOM positions with new data → `stale_ref` (caught by textHash + ancestorIdHint changing)
- Adding a `data-testid` or `id` to your targets makes refs much more robust

## Workflow

```powershell
flmux browser snapshot
flmux browser click @e1
flmux browser wait load
flmux browser snapshot          # refresh refs for new page
flmux browser click @e2
```

## Failure recovery

`stale_ref` → re-`snapshot`. Don't retry the same ref. The new snapshot's refs may have different numbers — read the new output to find the element you need.

If the element you want has no role/name (decorative div, custom widget), prefer CSS selectors or `testid=` over hoping for a ref.

## Multiple frames

A ref lives in a specific frame. `snapshot` without `--frame` covers the main frame. To get refs inside iframes (Stripe Elements, embedded forms), use `--frame <frameId>` once `list-frames` returns the frame.
