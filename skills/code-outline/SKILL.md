---
name: code-outline
description: Compact outline of .ts/.js files — top-level functions, classes, types. More compact than Read or LSP documentSymbol for large files.
---

Run `bun scripts/outline.ts <file>` (TS/JS only). Output: tab-separated `line<TAB>kind<TAB>name<TAB>export-flag`.

Kinds: `f` function/arrow, `c` class, `i` interface, `t` type alias, `m` method, `d` default export. Empty fourth column means not exported.

Requires `typescript` package.
