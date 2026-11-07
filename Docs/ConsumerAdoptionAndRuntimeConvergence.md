# Consumer adoption and runtime convergence

Phase 24 moves the unified language-provider contract from a package boundary
to the three principal interactive consumers. It also makes the ownership of
the deterministic LR runtime explicit instead of allowing front ends to imply
that they own independent parser implementations.

## Shared document lifecycle

`LanguageToolingDocument` is the reusable consumer-side actor. It owns one
`LanguageToolingSession`, enforces monotonically versioned snapshots and exact
source changes, and forwards completion, navigation, semantic-token,
formatting, and preview requests. Language kits still own language policy;
front ends still own transport, UI, persistence, and visualization.

The adoption paths are:

- ModEdit exposes external PL/0 and its permanent Markdown, HTML, and LaTeX
  providers through `LanguageToolingProvider`. Bundled providers retain their
  native scanners and previews while projecting disjoint LSP semantic tokens.
- Grammar-REPL exposes `GrammarREPLToolingConsumer`, a small headless adapter
  over the shared document actor.
- Grammar-Workbench exposes `GrammarWorkbenchToolingConsumer` from its SDK,
  including completion, definition, and semantic-token queries.

All three paths are tested with a real external `PL0Provider`. ModEdit also
tests every permanent bundled provider through the same lifecycle.

## LR runtime ownership and convergence

Grammar-REPL's incremental session executes `LRIncrementalRuntime`, reports its
native reuse evidence, and compares acceptance and recovery-edit count with
the positioned compatibility parse. `runtimeConverged` records that agreement.
The compatibility parse remains necessary until native runtime nodes can be
projected directly to positioned parse trees.

Grammar Workbench already delegates LR construction to `LRParser` and table
execution to `LRTableRuntime`. Its incremental analysis snapshot now publishes
`GrammarRuntimeConvergenceEvidence`, naming those package owners and pairing
them with lexical and parsing execution evidence. This is ownership evidence,
not a claim that two redundant runtimes were compared.

## Deliberate boundaries

- `LanguageToolingDocument` does not choose a provider or retain UI state.
- Bundled ModEdit languages remain permanent ModEdit-owned providers; they do
  not become external packages merely to share a consumer API.
- Consumer equivalence covers the provider contract. Parser-engine differential
  campaigns remain in the Incremental-Parsing and language-kit test layers.
- Native LR tree projection and generalized-runtime consumer adoption remain
  later work.

