# Ecosystem adoption alignment

Phase 15 establishes one local source graph for the parser ecosystem and moves
the first consumers from inferred reuse to engine-owned evidence.

## Workspace dependency policy

The coordinated development workspace resolves Grammar, Parser, Lexer,
LL-Parsing, LR-Parsing, Earley-Parser, Earley-TableParser, CYK-Parser,
RNGLR-Parser, Compiler, and Incremental-Parsing through neighboring paths.
This prevents a root package from compiling a released engine beside a local
copy of one of its foundational modules. SwiftPM currently warns about those
duplicate identities and intends to reject them in a future release.

Published releases should replace the local paths with one coordinated set of
compatible tags. A release graph must never mix a local foundation with a
remote package having the same SwiftPM identity.

## Adoption matrix

| Consumer | Native facility | Phase-15 status |
|---|---|---|
| PL0 reference parser | LL region cache and recovery replay | active |
| PL0 generated LR | LR stack checkpoints | active; positioned tree remains a full projection |
| PL0 Earley | live dependency-indexed chart session | adopted; prefix columns and BSR are retained |
| PL0 compiler | Compiler stable semantic/IR sessions | dependency aligned; PL/0 static-link semantics still use its own backend |
| Grammar-REPL LR | LR stack checkpoints | active; positioned parse retained as differential oracle |
| Grammar-Workbench LR | Workbench checkpoint runtime | active but still a parallel implementation |
| RNGLR consumers | Live GSS/BSR/SPPF session | adopted by PL/0 ecosystem comparison; prefix state is retained and replay is differential-tested |

No stable token prefix is reported as parser-state or chart reuse. Either an
engine-owned facility supplies the measurement or the adapter publishes full
or fallback execution.

## LR adoption boundary

`LRParser.incrementalRuntimeTable()` converts a generated automaton into the
canonical table consumed by `LRIncrementalRuntime`. The conversion preserves
stable production identities, selected ACTION cells, GOTO cells, and neutral
terminal names. `incrementalRuntimeTokens(for:)` exposes the parser's existing
source-tokenization policy for clients such as Grammar-REPL; language kits with
their own lexer pass neutral terminal names directly.

PL/0 still constructs its source-positioned ecosystem tree through the normal
parser adapter because `LRRuntimeNode` does not carry source ranges. The native
runtime nevertheless owns the stack execution and its reuse evidence. A future
positioned runtime-node projection can remove the second tree-building pass
without changing the public evidence contract.

## Remaining convergence work

- prove safe relocation for converged Earley suffix columns and forest extents;
- prove safe relocation for converged RNGLR suffix GSS and forest extents;
- choose one package-owned LR runtime for Grammar-Workbench after preserving
  its recovery, replay, and source-range guarantees;
- define a Compiler adapter that preserves PL/0 lexical-level/static-link
  semantics before claiming semantic or IR reuse there; and
- use the Phase-31 compatibility manifest plus a downstream exact-revision
  lock when replacing local paths with coordinated distribution tags.
