# Recovery quality and resumed recovery

Phase 30 makes generalized recovery measurable and interruptible without
moving a parser algorithm into Incremental-Parsing.

## Exact quality evidence

`Parser.GeneralizedRepairQuality` reports facts rather than a synthetic score:

- minimum edit cost returned by the breadth-first search;
- insertion and deletion counts;
- cumulative candidate states recognized;
- the number of states already completed when this attempt resumed; and
- whether the configured search-state limit was reached.

These values let campaigns compare repair size, repair shape, and search work
independently. They deliberately do not assert that an insertion is always
better than a deletion, since that judgment belongs to a language-specific
corpus or policy.

## Resumable bounded search

`GeneralizedRecoverySearchSession` retains the deterministic breadth-first
queue, visited candidate set, cursor, and any completed result. If recovery
reaches `maximumExploredStates`, a later request for the same input, ordered
insertion vocabulary, and maximum edit cost can raise the state budget and
continue at the next untested candidate. Previously recognized candidates are
not submitted to the owning parser again.

A changed input, vocabulary, or edit-cost bound starts a fresh checkpoint.
This fail-closed identity rule prevents a repair frontier from one document or
policy being mistaken for valid state in another. `reset()` also discards the
checkpoint explicitly.

Earley and RNGLR expose an optional shared-search session on their existing
`parseRecovering` entry points. Recognition and final forest construction
remain native to each engine; only the engine-independent candidate frontier
is shared. Successful recovery still produces a real Earley or RNGLR SPPF.

## Current boundary

This phase resumes an interrupted recovery search for an identical token
request. It does not transplant a repair frontier across a source edit, because
positions and candidate histories would require a proven mapping through
stable token identities. Live Earley and RNGLR parsing continue to own their
separate native edit-resumption state. A later phase can map recovery nodes
through the lexer change map and reuse only dependency-independent frontier
regions, with clean recovery as the differential oracle.
