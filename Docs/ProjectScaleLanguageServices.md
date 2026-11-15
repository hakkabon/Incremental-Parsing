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

## Phase 42 workspace scheduling

`LanguageToolingWorkspace` accepts complete source generations without running
providers. A diagnostic or navigation request analyzes the latest generation
through the transactional project host. Subsequent requests share the
materialized generation. Results carry the revision and include document
analysis evidence when the request triggered materialization.

Interactive requests run ahead of queued background diagnostics. A newer
submission rejects obsolete queued requests and requests cancellation of
running work. Providers and resolvers can cooperate with cancellation, and the
scheduler checks the generation again before returning any result. An edit
based on a skipped generation falls back to its full source snapshot.

Queue and document limits bound admission. The host retains one committed
project and the latest source submission, with temporary staged state during
analysis. A resolver can inspect the whole project, so the first query still
materializes all required documents. Stage-specific provider demands,
compiler scheduling and byte-based cache eviction require additional contracts.

## Phase 43 persistent semantic index

`PersistentSemanticIndex` stores declarations, references, and direct
dependencies per document. Replacing a document updates its reverse symbol
and dependency entries. A resolver can query transitive dependents before
replacing affected records.

Checkpoints use versioned JSON and atomic file replacement. On restart,
restore against a current document manifest. A record is reusable when its
URI, SHA-256 source digest, language, grammar artifact, producer version, and
binding fingerprint match. Reconcile returns the current documents whose
records need to be rebuilt. The producer must include imported interfaces,
unresolved imports and configuration in the binding fingerprint wherever
they affect name resolution.

The resolver owns the index, checkpoint timing, and storage location.
Storage currently writes one checkpoint for the project. Hosts can adopt it
through a language-owned resolver when that resolver supplies project keys
and dependency fingerprints.

## Phase 46 resource limits

Workspace admission limits the combined UTF-8 size of submitted source,
edit bases, and replacement text, along with the number of edit operations.
An over-budget submission leaves the previous generation available.
Semantic checkpoint reads stop at their byte budget before decoding, and
oversized writes leave the previous checkpoint in place. These limits cover
the input and checkpoint payloads. Parser state and decoded index allocations
have separate lifetimes and are outside these byte budgets.

## Next adoption step

Language kits with real module systems should implement a resolver and map
their module graph to `CompilerProjectSnapshot`. Product hosts can then add LSP
transport, background scheduling, and persistent indexes without changing the
language-provider contract.
