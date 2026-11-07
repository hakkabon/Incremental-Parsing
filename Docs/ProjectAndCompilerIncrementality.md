# Project and compiler incrementality

Phase 22 raises Compiler's stable semantic and IR reuse from a list of syntax
units to a revisioned project boundary.

## Project contract

`CompilerProjectSnapshot` is an atomic, monotonically revisioned collection of
`CompilerProjectModule` values. A module has a stable identity, direct imports,
and compiler units whose identities are unique across the project. Validation
rejects stale revisions, duplicate modules, missing imports, and duplicate unit
identities before compilation begins.

All modules enter Compiler's canonical whole-program semantic pipeline. This
keeps function, symbol, and type resolution owned by Compiler rather than by a
project adapter. Direct imports add explicit module dependency edges to the
existing semantic dependency graph.

## Invalidation policy

Module interfaces are fingerprinted independently from implementation bodies:

- a function interface contains its name, parameter types, and return type;
- a record interface contains its name and ordered fields;
- a variable interface contains its declared type; inferred declarations also
  include their initializer conservatively.

A body-only edit rebuilds the defining semantic and IR units but does not
invalidate importers when the public interface is stable. An interface change
invalidates every unit in its transitive reverse-import closure. This is
conservative for modules that hide an imported interface, but safe for modules
that expose imported types. Ordinary fine-grained function, symbol, and type
dependencies still operate within that boundary.

Grammar revisions compose with the same project update: the verified
`GrammarChangeSet` reaches the underlying compiler session, while module edges
cover project-level changes.

## Output convergence and evidence

`CompilerLinkedOutput` retains reference identity when the canonical
whole-program `IRProgram` is equal after an update. This is independent from
semantic and fragment reuse: project metadata or intermediate nodes may change
without manufacturing a new linked output.

Evidence now reports four independent compiler layers:

| Dimension | Meaning |
| --- | --- |
| `semanticNodes` | Stable typed compiler units |
| `irNodes` | Stable relocatable IR fragments |
| `compilerModules` | Project modules retained without semantic rebuild |
| `linkedOutputs` | Canonical whole-program IR outputs retained exactly |

The project campaign compares every incremental result with a fresh project
session, including source AST, typed AST, symbols, and linked IR.

## Current boundary

Compiler still performs canonical whole-program semantic analysis to derive the
next candidates before its stable-node arenas converge. Phase 22 therefore
establishes correct project invalidation, identity retention, and measurement;
it does not yet claim demand-driven or parallel semantic analysis. A later
phase can split declaration indexing and function-body checking into separately
scheduled tasks without changing the project-facing contract.
