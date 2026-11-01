# Incremental Parsing

Shared foundations for incremental parsers and robust syntax-error recovery in
Swift.

This package sits below parser implementations. It has no dependencies and no
knowledge of a particular grammar, lexer, syntax tree, parser algorithm, editor,
or UI toolkit. In particular, parser packages must never depend on ModEdit.

## What belongs here

- immutable, revisioned source snapshots;
- validated edits in UTF-16 coordinates (TextKit/LSP compatible);
- coordinate mapping across replacements;
- a concurrency-safe incremental parse session and parser contract;
- parser-neutral diagnostics and bounded recovery plans.

Language-specific tokenization, grammar definitions, syntax trees, formatting,
semantic analysis, and editor visualization belong in language or application
packages. ModEdit may consume this library; dependency arrows never point back
to the editor.

```text
Grammar / Lexer / Parser foundations
                 │
                 ▼
        IncrementalParsing
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
parser engines       language packages
                           │
                           ▼
                         ModEdit
```

## Example

```swift
import IncrementalParsing

var snapshot = SourceSnapshot(text: "let answer")
let edit = SourceEdit(
    baseRevision: snapshot.revision,
    range: SourceRange(location: 10, length: 0),
    replacement: " = 42"
)
let change = try edit.applying(to: snapshot)
snapshot = change.after
```

Implement `IncrementalParser` to receive the previous result and a validated
`SourceChange`. When a client cannot describe an exact edit, the session passes
`change: nil`, which is an explicit request for the parser's safe full-parse
path.

## Development

```sh
swift build
swift test
```

Swift 6.1 or newer is required.
