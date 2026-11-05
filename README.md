# Incremental Parsing

Shared foundations for incremental parsers and robust syntax-error recovery in
Swift.

This package sits below parser implementations. It has no dependencies and no
knowledge of a particular grammar, lexer, syntax tree, parser algorithm, editor,
or UI toolkit. In particular, parser packages must never depend on ModEdit.

## What belongs here

- immutable, revisioned source snapshots;
- validated edits in UTF-16 coordinates (TextKit/LSP compatible);
- atomic sequential edit batches with externally supplied monotonic revisions;
- coordinate mapping across replacements;
- a concurrency-safe incremental parse session and parser contract;
- parser-neutral diagnostics and bounded recovery plans;
- open reuse dimensions, stable fallback reasons, and artifact identities; and
- an incremental-versus-clean differential campaign runner; and
- host-qualified measurement reports, deterministic fingerprints, summaries,
  and release quality gates.

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
`SourceChange`. A change may contain one replacement or an atomic sequential
batch; its composed mapping translates offsets across the complete transition.
When a client cannot describe an exact edit, the session passes `change: nil`,
which is an explicit request for the parser's safe full-parse path.

`IncrementalExecutionEvidence` reports full, incremental, or fallback execution
without exposing engine-owned state. Reuse remains multidimensional: token,
parser-state, syntax, chart, forest, semantic, and IR counts are never blended
into a single percentage. See [Contract consolidation](Docs/ContractConsolidation.md).

`IncrementalMeasurementRunner` productizes that evidence without turning this
package into a benchmark suite. Language kits define named scenarios and invoke
their real incremental and clean paths. The runner performs warmups, captures
measured samples, aggregates each reuse dimension, and emits a verified JSON
report. Its evidence fingerprint excludes host and time; its measurement
fingerprint binds both. This lets front ends compare correctness across machines
without pretending that their timings are comparable. See
[Productization and measurement](Docs/ProductizationAndMeasurement.md).

The coordinated workspace now uses one local source graph and adopts native LR
checkpoint evidence in PL/0 and Grammar-REPL. The current adoption matrix and
the deliberately disclosed Earley/Compiler gaps are recorded in
[Ecosystem adoption alignment](Docs/AdoptionAlignment.md).

The PL/0 product campaign now runs the same accepted, recovery, incremental
lexer, LL, LR, Earley-disclosure, and semantic scenarios through ModEdit,
Grammar-REPL, and Grammar-Workbench. See
[Product campaign](Docs/ProductCampaign.md).

## Development

```sh
swift build
swift test
```

Verified reports can be inspected or gated without an application dependency:

```sh
swift run incremental-report verify report.json
swift run incremental-report compare modedit.json repl.json workbench.json
swift run incremental-report gate report.json budgets.json
```

Swift 5.9 or newer is required.
