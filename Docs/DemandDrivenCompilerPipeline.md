# Demand-driven compiler pipeline

Phase 29 separates revision adoption from compiler artifact materialization.
The earlier incremental and project sessions remain the owners of stable-node
and module invalidation; the new demand session is a scheduling layer for
consumers that do not need every compiler product after every edit.

## Contract

`CompilerDemandDrivenSession.update(_:revision:)` installs a monotonically
revisioned `ASTNode` and executes no compiler pass. A consumer can subsequently
demand one of five stages:

| Demand | Materialized prerequisite chain |
| --- | --- |
| Semantic result | semantic analysis |
| IR | semantic analysis, IR lowering |
| Linked IR | semantic analysis, IR lowering, link convergence |
| Stack bytecode | shared chain, stack backend |
| Register bytecode | shared chain, register backend |

Stages already in the session are reused. Stack and register generation are
independent leaves, so requesting the second backend does not repeat semantic
analysis, lowering, or linking. Installing equivalent syntax under a newer
revision retains every materialized result. Installing changed syntax clears
the dependent chain before any new pass is run.

Revision errors fail closed: a demand before the first update reports
`noRevision`, and non-increasing revisions are rejected without mutating the
active session.

## Evidence and adoption

Every demand returns its value together with ordered executed and reused stage
lists. `IncrementalExecutionEvidence` reports `compilerStages`; link demands
also report `linkedOutputs`, and backend demands report the new
`bytecodeOutputs` dimension. This avoids folding scheduling, semantic-node,
IR-node, module, and final-output reuse into one misleading number.

The `comp` executable now installs its AST into this session and obtains typed
AST, IR, and the selected backend through demands. It therefore exercises the
same public path as an editor, REPL, workbench, or language kit can use.

## Relationship to the existing compiler sessions

The three boundaries are complementary:

- `CompilerIncrementalSession` owns dependency-indexed semantic-node and IR
  fragment convergence;
- `CompilerProjectSession` owns atomic module graphs, interface invalidation,
  and linked-output convergence;
- `CompilerDemandDrivenSession` owns lazy artifact scheduling for a revisioned
  document and independent backend leaves.

Phase 29 intentionally does not claim fine-grained lazy type checking. A
changed document currently invalidates the demand session's complete artifact
chain. The next compiler step can combine the scheduler with the stable-unit
dependency graph so an individual function body, diagnostic query, completion
request, or code-generation target activates only the required semantic and IR
tasks. That work can preserve this consumer-facing demand contract.
