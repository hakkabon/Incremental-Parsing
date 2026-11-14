# Project-scale language services

Phase 40 adds the first shared multi-document language-service boundary.

## Contract

Language-Tooling now owns `LanguageToolingProject`, a revisioned actor that:

- selects providers by language identity;
- creates URI-aware document sessions;
- forwards exact source changes, retains unchanged documents, and measures
  document reuse;
- removes documents absent from the next atomic project view;
- aggregates diagnostics by URI; and
- exposes definition, references, and workspace rename through one API.

The new `documents` reuse dimension keeps project orchestration evidence
separate from token, parser-state, syntax, semantic, IR, and compiler-module
reuse.

## Policy boundary

Cross-file binding is not inferred by the host. A language kit supplies a
`LanguageToolingProjectResolver` to own module/import graphs, visibility,
overload selection, and global symbol identities. This keeps ModEdit,
Grammar-REPL, Grammar-Workbench, and prospective LSP transports interchangeable
and prevents application policy from entering parser packages.

PL/0 and Pascal now honor URI-aware session creation. ModEdit can construct the
shared project actor directly from its unified provider registry, and its PL/0
adapter forwards real document URIs.

## Compiler relationship

Compiler's existing `CompilerProjectSession` remains the owner of semantic/IR
dependency invalidation and module-interface propagation. A language resolver
may feed that session from its project model; Language-Tooling does not import
Compiler or duplicate its graph. Thus document reuse and compiler-module reuse
remain independently measurable.

## Phase 41 foundations

Changed documents are staged in separate provider sessions before publication.
An exact edit seeds its staged session from the committed source, then applies
the change. This preserves retry and isolation at the cost of reanalyzing the
base for changed documents until providers can fork sessions. Reads of
committed diagnostics remain available during a pending update. Overlapping
asynchronous operations return `operationInProgress`. Resolvers must preserve
their committed state when rejecting an update.

Grammar-REPL and Grammar-Workbench expose project factories alongside their
document adapters. Project completion can delegate to the language resolver.
Compiler uses reverse import edges to invalidate transitive dependents after
interface or import-list changes.

PL/0 publishes range-derived diagnostic IDs for the current revision before
linking repairs. Engines can still retain structural IDs internally.

## Next adoption step

Language kits with real module systems should implement a resolver and map
their module graph to `CompilerProjectSnapshot`. Product hosts can then add LSP
transport, background scheduling, and persistent indexes without changing the
language-provider contract.
