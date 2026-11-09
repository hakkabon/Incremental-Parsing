# Grammar-change incrementality

Phase 21 extends incrementality from source edits to grammar revisions. The
shared contract remains deliberately small: `Grammar` describes what changed,
while each engine decides which of its native artifacts can be retained safely.

## Shared grammar identity and change sets

`GrammarProductionID` is a stable structural identity derived from a
production's goal and ordered symbols. `Grammar.incrementalSemanticFingerprint`
binds the start symbol, the set of structural productions, and the ordered
lexical specification. Reordering productions therefore does not manufacture a
change, while reordering lexical rules does because lexical priority is
observable.

`Grammar.changeSet(to:)` reports added, removed, retained, and invalidated
production identities. Invalidated productions include the transitive reverse
dependency closure: changing a referenced nonterminal also invalidates
productions whose results can depend on it. A start-symbol change or lexical
change is conservative. Lexical changes additionally set
`requiresRetokenization`.

The change set carries both source and target fingerprints. Consumers verify
both before retaining state; a stale, fabricated, or misapplied delta must fail
closed.

## Engine behavior

| Consumer | Retained for a production-only change | Conservative boundary |
| --- | --- | --- |
| Lexer | Entire restart-and-converge token cache | Any lexical rule or priority change clears the cache |
| Earley | Chart facts with no dependency path to an invalidated production | Fingerprint mismatch performs the normal full bind |
| RNGLR | Unaffected forest nodes | The GSS is rebuilt because generated automaton state numbers do not yet have cross-grammar identity |
| Compiler | Semantic and IR units not dependent on invalidated productions | Unverified artifact changes retain nothing |
| LR | Nothing yet | A parse-table change invalidates checkpoints because LR state correspondence is not yet proven |

All successful transitions publish `grammarProductions` alongside their native
reuse dimensions. Counts stay separate: retained productions are not presented
as retained tokens, chart facts, forest nodes, semantic nodes, or IR nodes.

## Normalization and provenance

Structural identities describe the grammar actually consumed by an engine. A
consumer that normalizes or lowers a source grammar must therefore compute the
change set over the lowered grammars, or maintain explicit source-to-lowered
production provenance. Comparing source IDs directly with generated production
IDs is not a safe shortcut.

## Campaign adoption

Phase 27 adds a shared hot-reload campaign runner and a PL/0 campaign consumed
unchanged by ModEdit, Grammar-REPL, and Grammar-Workbench. It verifies the
artifact chain, atomic rejection, retained document revision, engine evidence,
and equivalence with clean target execution. The next deeper engine work is
stable generated-state correspondence for LR and RNGLR, followed by live
cross-grammar parser-session adoption where correctness can be proven.
