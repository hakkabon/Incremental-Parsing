# Grammar-change and engine convergence

Phase 39 moves grammar activation from engine-specific experiments into live
parser sessions with comparable evidence.

## Shared transition report

`GrammarEngineTransition` identifies the engine, exact source and target
artifacts, whether activation reused native state, whether the lexical pipeline
must retokenize, and the engine's `IncrementalExecutionEvidence`. Every report
contains the `grammarProductions` dimension; native dimensions remain separate.

The contract does not import Grammar. `GrammarChangeSet` remains owned by the
Grammar package, while parser engines project the result of applying that delta
onto the dependency-free transition report.

## Native engine behavior

### LR

Generated runtime tables now carry stable identities for their LR item-set
states and the source grammar fingerprint. For a verified production-only
delta, the runtime maps checkpoint stack states into the new table and resumes
from the latest checkpoint whose complete stack has a correspondence. A stale
delta, lexical change, missing state identity, forced conflict choice, or
invalid previous result still fails closed.

### Earley

`EarleyIncrementalSession.transition(to:change:)` replaces the grammar inside
the existing document session. Dependency-indexed chart facts are invalidated
by production identity. Live chart columns containing invalidated productions,
and every subsequent column, are replayed; an unrelated prefix survives.

### RNGLR

`RNGLRIncrementalSession.transition(to:change:)` activates the new automaton in
the existing document session. Numeric automaton states remain grammar-local,
so the GSS and restart boundaries are rebuilt. Production-independent forest
nodes remain interned and are reported separately. This distinction prevents
forest reuse from being misreported as GSS reuse.

## Correctness boundary

All transitions validate both delta fingerprints. Lexical changes force
retokenization and parser restart. Engine tests compare the post-transition
result with a clean parse under the target grammar. Transition evidence is
therefore a description of proven native reuse, not an activation promise.

## Next boundary

The PL/0 product campaign still provides the cross-front-end activation gate.
A later campaign can aggregate the new LR, Earley, and RNGLR transition reports
for the same language-kit grammar mutation and apply per-engine performance
budgets without changing their native reuse policies.
