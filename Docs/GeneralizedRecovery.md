# Generalized recovery

Phase 20 makes recovery an engine capability instead of a language-kit parser
replacement.

## Shared policy

`Parser.GeneralizedRecoverySearch` performs a deterministic breadth-first
minimum-edit search over token sequences. It accepts an ordered insertion
vocabulary and an engine recognizer closure. `GeneralizedRecoveryPolicy` places
hard bounds on edit cost and explored states, and the result reports whether a
search limit was reached. Delete candidates precede insert candidates, repeated
token sequences are visited once, and all edit scripts are replayable in order.

The shared search projects terminal repairs to `Parser.RecoveryEdit`, so the
same evidence can feed diagnostics, incremental recovery replay and consumer
comparisons.

## Native generalized-engine adoption

- Earley materializes any `Lexer.TokenStream`, invokes the shared search only
  after native failure, and reparses the repaired stream. A recovered result
  therefore contains the native BSR and SPPF.
- RNGLR applies the same policy to its token keys and reparses repaired source
  through its native tokenizer and GSS algorithm. Its result likewise retains
  the native BSR and SPPF.
- Neither adapter claims recovery when the budget is exhausted. Rejection and
  budget exhaustion remain inspectable outcomes.

## Pascal trial

`Pascal-LanguageKit` supplies only a small ordered synchronization vocabulary;
it does not implement a recovery algorithm. Clean acceptance, recovered syntax
and lexical rejection are distinct results. Successful syntax repairs expose
portable insert/delete evidence, warning diagnostics, search-state counts and a
real Earley forest. The provider now advertises the unified `recovery`
capability.

This phase intentionally stops short of a typed Pascal recovery CST. That
projection belongs above the generalized forest and should preserve inserted
and deleted-token provenance rather than replacing the engine result.

## Safety properties

- search always terminates at an explicit edit or state budget;
- the chosen repair is deterministic for a fixed candidate order;
- successful recovery is verified by the owning parser engine;
- clean input never acquires invented repairs; and
- lexical failure is not silently reclassified as syntactic recovery.
