# Contract consolidation

Phase 9 makes this package the shared transition and operational-evidence
vocabulary for the parser ecosystem. It remains dependency-free and contains
no grammar, token, syntax-tree, parser-algorithm, language, editor, or UI type.

## Ownership

| Concern | Owner |
|---|---|
| UTF-16 snapshots, revisions, replacements, batches and offset maps | IncrementalParsing |
| Artifact identity, reuse dimensions, execution strategy and fallback reason | IncrementalParsing |
| Grammar-production reuse evidence across verified grammar revisions | IncrementalParsing |
| Project-module and linked-output reuse evidence | IncrementalParsing |
| Differential incremental-versus-clean validation | IncrementalParsing |
| Portable parse trees, forests, diagnostics and parser results | Parser |
| Stable token identity and restart/convergence | Lexer |
| LR stacks, Earley charts, GSS/SPPF nodes and other native state | engine package |
| Grammar meaning, production identity and normalization provenance | Grammar |
| Language policy, messages, semantics and formatting | language kit |
| Presentation, code actions and visualization | client application |

## Adopted bridges

- Lexer accepts a shared `SourceSnapshot` and `SourceChange`. A multi-edit
  transition safely selects full tokenization until native batch convergence is
  implemented.
- Parser converts normalized insert/delete/skip scripts into source-coordinate
  `RecoveryAction` values when the lexer supplies stable token IDs and ranges.
- PL0-LanguageKit converts its compatibility snapshots, grammar artifact and
  reuse counters to shared contracts. Existing public APIs remain available.
- Grammar-Workbench delegates sequential UTF-16 edit application to
  `SourceEditBatch` and projects its lexing, parsing and identity metrics into
  shared operational evidence.
- Grammar-REPL accepts shared revisioned snapshots and truthfully describes its
  current full-validation path as fallback evidence.
- Grammar computes structural fingerprints and transitive production change
  sets; consumers validate both endpoints before retaining native state.

## Batch semantics

Replacements are ordered and interpreted against the result of the preceding
replacement, matching LSP content-change arrays. The batch is applied to a
private value and advances the revision once only after every replacement has
validated. A caller may preserve a non-consecutive external revision as long as
it increases monotonically.

## Differential validation

`DifferentialValidation` creates a clean parser at every campaign revision and
compares an identity-neutral projection with the stateful incremental result.
It is deliberately generic: engine and language packages define the projection
that represents their observable correctness contract.

## Release boundary

Local development continues to use one neighboring SwiftPM source graph so a
workspace cannot accidentally combine local and released copies of the same
package identity. Phase 31 records the publishable compatibility graph in
`Release/EcosystemRelease.json`. A distribution host replaces paths with tags
from one exact revision lock; the compatibility manifest itself does not claim
that uncreated tags or remote artifacts already exist.
