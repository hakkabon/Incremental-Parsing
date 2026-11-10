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
- grammar-production reuse evidence for verified grammar revisions; and
- project-module and linked-compiler-output reuse evidence; and
- an incremental-versus-clean differential campaign runner; and
- host-qualified measurement reports, deterministic fingerprints, summaries,
  and release quality gates; and
- a UI-neutral language-provider/session API shared by external language kits
  and permanently bundled application languages.

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

External language kits and application-bundled languages now share the same
revisioned provider/session boundary. See
[Unified language-provider API](Docs/UnifiedLanguageProvider.md).

Grammar source and lexical execution now have one ownership path:
`GrammarTokenizer` and `GrammarParser` produce an ordered lexical specification,
`Lexer` executes it in both clean and restart-and-converge modes, and language
kits provide only typed projections. See
[Grammar and lexical pipeline](Docs/GrammarAndLexicalPipeline.md).

The first independent language-kit trial now exercises that path with compact
Pascal, including case-insensitive keywords, lossless incremental tokenization,
generalized parsing, a portable provider and product measurements. See
[Pascal language-kit trial](Docs/PascalLanguageKitTrial.md).

Generalized recovery now uses one bounded deterministic repair search shared by
Earley and RNGLR. Successful retries retain the owning engine's BSR/SPPF, and
the Pascal trial exposes portable repair evidence through its language
provider. See [Generalized recovery](Docs/GeneralizedRecovery.md).

Grammar revisions now have stable structural production identities, transitive
change sets, and fail-closed adoption paths in Lexer, Earley, RNGLR, and the
Compiler. LR table changes remain deliberately conservative until generated
states have a proven cross-grammar correspondence. See
[Grammar-change incrementality](Docs/GrammarChangeIncrementality.md).

Compiler now accepts atomic revisioned projects with stable modules and direct
imports. Public-interface changes invalidate importers, implementation-only
edits remain local, and equal whole-program IR retains linked-output identity.
See [Project and compiler incrementality](Docs/ProjectAndCompilerIncrementality.md).

Editor-neutral language mechanisms now live in the sibling `Language-Tooling`
package. PL/0 projects its semantic graph and formatter mechanics into that
foundation, while Pascal independently adopts grammar-derived completion and
semantic tokens through the same tooling-session boundary. See
[Shared language tooling foundation](Docs/SharedLanguageTooling.md).

ModEdit, Grammar-REPL, and the Grammar-Workbench SDK now consume that boundary
through one revision-validating document lifecycle. ModEdit's permanent HTML,
Markdown, and LaTeX providers use the same consumer API as external kits, and
the REPL and Workbench publish explicit LR runtime convergence or ownership
evidence. See [Consumer adoption and runtime convergence](Docs/ConsumerAdoptionAndRuntimeConvergence.md).

Earley-Parser's dependency arena now participates in live parsing: stable token
prefixes retain real chart columns and BSR contributions, the changed suffix is
rebuilt by the native scanner/predictor/completer loop, and PL/0 plus Pascal
publish the resulting evidence. See
[Live Earley incrementality](Docs/LiveEarleyIncrementality.md).

RNGLR-Parser now resumes its real graph-structured stack from a pre-reduction
token boundary, retains safe BSR/forest state, and reports native graph, forest,
and token evidence. PL/0's ecosystem comparison supplies stable lexer token
identities to that live session. See
[Live RNGLR incrementality](Docs/LiveRNGLRIncrementality.md).

Grammar replacement now has a revisioned campaign contract with atomic
activation, clean-target validation, and fail-closed rejection. The PL/0 kit
drives production-only, lexical, combined grammar/source, and invalid reloads
through identical ModEdit, Grammar-REPL, and Grammar-Workbench entry points.
See [Grammar hot-reload campaigns](Docs/GrammarHotReloadCampaigns.md).

Pascal now provides an independent semantic/tooling adoption trial: stable
declaration and reference identities feed the shared tooling index for
completion, definition, references, hover, semantic tokens, and measured
semantic reuse. See
[Pascal semantic and tooling trial](Docs/PascalSemanticToolingTrial.md).

Compiler artifacts can now be materialized through a revisioned demand graph.
Submitting syntax performs no compiler work; semantic, IR, linked-IR, and
backend requests execute only their missing prerequisite chain and publish
separate stage and bytecode-output evidence. The `comp` executable consumes
this boundary directly. See
[Demand-driven compiler pipeline](Docs/DemandDrivenCompilerPipeline.md).

Generalized recovery now reports exact repair-quality facts and can retain a
bounded breadth-first search at budget exhaustion. Earley and RNGLR accept the
same parser-owned recovery session, so a larger follow-up budget continues at
the next untested candidate while preserving minimum-edit ordering. See
[Recovery quality and resumed recovery](Docs/RecoveryQualityAndResumption.md).

The coordinated release surface is now described by a validated, versioned
manifest covering all foundation, engine, tooling, language, and product
components. It pins compatibility floors and public schema ownership while
leaving exact commit locks and platform artifacts to downstream release hosts.
See [Release consolidation](Docs/ReleaseConsolidation.md).

PL0-LanguageKit's first surface-reduction pass removes consumer-specific
Workbench and LSP adapters and moves the language-neutral experiment protocol
to Language-Tooling. Provider diagnostics now cover syntax and semantics
through the same interface used by Pascal. See
[PL/0 surface reduction](Docs/PL0SurfaceReduction.md).

Phase 33 extracts the remaining language-kit substrate. Incremental-Parsing
now owns the canonical source position and compact compatibility input
envelope; Parser owns generic language syntax and parse products; Lexer owns
typed grammar-token projection; and LL-Parsing owns shared relocation
conformances. PL/0 contains only explicitly named PL/0 implementation files,
while Pascal independently exercises the shared lexical facade. See
[Language-kit substrate extraction](Docs/LanguageKitSubstrateExtraction.md).

Phase 34 converges diagnostics, ranges, source changes, and recovery projection
at language-provider boundaries. It also introduces a parser-free
`ModEdit-Bundled-Languages` distribution catalog: HTML, Markdown, and LaTeX are
active permanent providers, while JSON, Grammar notation, Graphviz DOT, and CSS
are reserved as independent language kits that ModEdit can bundle when ready.
See [Contract convergence and bundled languages](Docs/ContractConvergenceAndBundledLanguages.md).

Phase 35 supplies independent Grammar and JSON language kits and activates
them as permanent ModEdit providers. Grammar reuses the authoritative
`GrammarParser`; both kits use Lexer's restart-and-converge tokenization and
publish diagnostics, semantic tokens, and operation evidence through the
shared provider API. JSON also provides structural recovery and formatting.
See [Grammar and JSON providers](Docs/GrammarAndJSONProviders.md).

Phase 36 adds independent Graphviz DOT and CSS language kits and activates the
remaining reserved permanent providers. Parser now supplies shared balanced-
delimiter recovery, while both kits use Lexer's incremental tokenizer and the
unified tooling lifecycle. See [DOT and CSS providers](Docs/DOTAndCSSProviders.md).

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
swift run incremental-report release-manifest Release/EcosystemRelease.json
```

Swift 5.9 or newer is required.
