# PRD: JSON Compact Formatter

Status: needs-triage

## Problem Statement

Standard JSON pretty-printers produce one property per line, which is excessively verbose for structured data that contains many small, uniform objects (e.g. UI node trees, test fixtures). The result is hard to scan because the eye has to travel over many lines to read what is logically a single record. Minified JSON solves the verbosity but destroys readability entirely.

## Solution

A Zig formatter module that reads JSON from a reader and writes a compact-but-readable representation to a writer. The formatter applies a "fits-on-one-line → inline, otherwise expand" rule recursively, and additionally aligns values of matching keys across sibling objects in the same array, making repeated structures easy to scan column-by-column.

## User Stories

1. As a developer, I want small JSON objects to be collapsed to a single line, so that I don't have to scroll through unnecessary whitespace.
2. As a developer, I want large or deeply nested JSON to remain expanded across multiple lines, so that it stays readable without horizontal scrolling.
3. As a developer, I want the formatter to decide inline vs expanded based on a configurable line width, so that I can tune it to my terminal or editor.
4. As a developer, I want nested objects to be collapsed independently of their parents, so that only the nodes that actually fit are inlined.
5. As a developer, I want sibling objects in the same array to have their values aligned by key, so that I can scan columns of repeated structures quickly.
6. As a developer, I want the formatter to accept both minified and pretty-printed JSON as input and produce the same output, so that the input style does not matter.
7. As a developer, I want the formatter to report an error on invalid JSON input, so that I can detect malformed files early.
8. As a developer, I want to provide my own allocator, so that I control memory lifetime and can use arena allocation for batch workloads.
9. As a developer, I want to provide a reader and a writer, so that I can wire the formatter into any I/O pipeline (files, buffers, sockets).
10. As a library user, I want a single public function with a minimal signature, so that integration requires no configuration boilerplate.

## Implementation Decisions

### Public API

```zig
pub fn format(
    allocator: std.mem.Allocator,
    reader: std.io.Reader,
    writer: std.io.Writer,
    line_width: usize,
) !void
```

- `reader` and `writer` use the concrete `std.io.Reader` / `std.io.Writer` interface types from Zig 0.16 (not `anytype`).
- The allocator is used internally to build the in-memory JSON value tree; the caller owns it.
- `line_width` is the only formatting parameter for now. No options struct.

### Formatting algorithm

Two logical passes are needed:

1. **Measure pass** — walk the parsed value tree and compute, for each node, its inline rendering length. Also, for each array whose elements are objects, collect per-key maximum value widths across siblings for alignment padding.
2. **Emit pass** — walk the tree again. At each node: if its inline length ≤ (available width at current indent), emit inline with alignment padding; otherwise expand with 2-space indent per level, recursing into children.

### Inline rendering rule

- Try to render the entire node (object or array) on one line.
- If the rendered length fits within `line_width` minus current indentation, emit it inline.
- Otherwise emit in expanded form: opening bracket/brace, each child on its own indented line, closing bracket/brace.
- This rule applies recursively, so a deeply nested object may have some subtrees inlined and others expanded.

### Alignment rule

- Applies only to arrays whose elements are JSON objects.
- Scope: local to each array (siblings within the same array are aligned together; separate arrays align independently).
- For each key present in any sibling object, compute the maximum rendered value width across all siblings.
- When emitting an object inline within an aligned array, pad each value to the column width of that key.
- Alignment applies whether the sibling objects are rendered inline (each on its own line in an expanded array) or expanded (each property on its own line) — but in practice alignment is most visible when each object fits on one line.

### Parsing

Use `std.json.parseFromSlice` (or equivalent) to parse the reader content into a `std.json.Value` tree. The full input is read into memory before formatting begins.

### Indentation

2 spaces per nesting level.

## Testing Decisions

Tests should verify the formatter's observable output only — the string emitted to the writer — not internal data structures or intermediate representations. Tests should be black-box: change the implementation entirely and tests should still pass as long as output is correct.

The formatter module will be tested directly via its public `format` function. Input is wrapped in `std.io.fixedBufferStream` to produce a reader; output is collected into a `std.ArrayList(u8)` whose `.writer()` is passed to the formatter.

### Agreed test cases

All cases use `line_width = 80`.

---

**Test 1 — pretty-printed small flat object collapses to one line**

Input:
```json
{
  "kind": "fixed",
  "size": 100
}
```
Output:
```json
{"kind": "fixed", "size": 100}
```

---

**Test 2 — nested object with scalar-only children, all inline**

Input:
```json
{
  "painter": { "kind": "none" },
  "pos": { "x": 10, "y": 10 }
}
```
Output:
```json
{"painter": {"kind": "none"}, "pos": {"x": 10, "y": 10}}
```

---

**Test 3 — complex nested document, inner nodes collapse, outer expands**

Input:
```json
{
  "name": "test_no_children_fixed_position",
  "nodes": [
    {
      "painter": { "kind": "none" },
      "pos": { "x": 10, "y": 10 },
      "size": [{"kind": "fixed", "size": 100}, {"kind": "fixed", "size": 100}],
      "first_children": -1,
      "last_children": -1,
      "next": -1
    }
  ]
}
```
Output:
```json
{
  "name": "test_no_children_fixed_position",
  "nodes": [
    {
      "painter": {"kind": "none"},
      "pos": {"x": 10, "y": 10},
      "size": [{"kind": "fixed", "size": 100}, {"kind": "fixed", "size": 100}],
      "first_children": -1,
      "last_children": -1,
      "next": -1
    }
  ]
}
```

---

**Test 4 — array of 2 sibling objects, values aligned**

Input:
```json
[{"size": 100, "kind": "fixed"}, {"size": 2000, "kind": "fixed"}]
```
Output:
```json
[
  {"size":  100, "kind": "fixed"},
  {"size": 2000, "kind": "fixed"}
]
```

---

**Test 5 — minified array of 5 sibling objects, each fits inline, aligned**

Input:
```json
[{"kind":"fixed","size":100},{"kind":"fixed","size":2000},{"kind":"relative","size":50},{"kind":"fixed","size":7},{"kind":"relative","size":333}]
```
Output:
```json
[
  {"kind": "fixed",    "size":  100},
  {"kind": "fixed",    "size": 2000},
  {"kind": "relative", "size":   50},
  {"kind": "fixed",    "size":    7},
  {"kind": "relative", "size":  333}
]
```

---

**Test 6 — fully pretty-printed array of 5 objects → same output as test 5**

Input:
```json
[
  {
    "kind": "fixed",
    "size": 100
  },
  {
    "kind": "fixed",
    "size": 2000
  },
  {
    "kind": "relative",
    "size": 50
  },
  {
    "kind": "fixed",
    "size": 7
  },
  {
    "kind": "relative",
    "size": 333
  }
]
```
Output: identical to test 5.

---

**Test 7 — same array nested inside a parent object**

Input:
```json
{
  "name": "my_widget",
  "size": [
    {"kind": "fixed", "size": 100},
    {"kind": "fixed", "size": 2000},
    {"kind": "relative", "size": 50},
    {"kind": "fixed", "size": 7},
    {"kind": "relative", "size": 333}
  ]
}
```
Output:
```json
{
  "name": "my_widget",
  "size": [
    {"kind": "fixed",    "size":  100},
    {"kind": "fixed",    "size": 2000},
    {"kind": "relative", "size":   50},
    {"kind": "fixed",    "size":    7},
    {"kind": "relative", "size":  333}
  ]
}
```

## Out of Scope

- **Global alignment** across separate arrays in the document (deferred; local-only is the initial target).
- **Comment preservation** — JSON does not have comments; JSONC/JSON5 is not supported.
- **Streaming output** — the full input is parsed into memory before any output is emitted.
- **Options struct** — no configuration beyond `line_width` for now.
- **CLI binary** — this is a library module only.
- **Custom indent size** — fixed at 2 spaces.

## Further Notes

The formatting problem requires a two-pass approach because alignment padding can only be computed after all sibling values have been measured. An alternative one-pass approach would require buffering each object's output before flushing it, which is functionally equivalent.

Global alignment (across arrays) is a natural future extension but requires a full-document measure pass and a schema-inference step to group objects by structural type. Left for later.
