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

## Next adoption step

Language kits with real module systems should implement a resolver and map
their module graph to `CompilerProjectSnapshot`. Product hosts can then add LSP
transport, background scheduling, and persistent indexes without changing the
language-provider contract.
