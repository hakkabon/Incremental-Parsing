# Release consolidation

Phase 31 turns the accumulated platform contracts into one reviewable release
envelope without turning Incremental-Parsing into a monorepo or application
packager.

## Coordinated manifest

`Release/EcosystemRelease.json` covers 19 components in five ordered layers:

1. foundations: Grammar, tokenization, Lexer, Parser, and shared incremental
   contracts;
2. parser engines: LL, LR, Earley, CYK, and RNGLR implementations;
3. shared tooling and Compiler;
4. PL/0 and Pascal language kits; and
5. ModEdit, Grammar-REPL, and Grammar-Workbench products.

Each component declares its canonical SwiftPM identity, minimum compatible
version, maturity, and in-scope dependencies. Public data contracts declare a
single owner and schema version. The manifest distinguishes compatibility
floors from source locks: it does not pretend that an untagged workspace commit
has already been published.

`EcosystemReleaseManifest` validates the envelope while decoding. It rejects:

- malformed versions, package names, identities, and release identifiers;
- duplicate package names or case-folded SwiftPM identities;
- missing and duplicate dependencies;
- dependencies from a lower layer to a higher layer;
- dependency cycles; and
- duplicate contracts, non-positive schemas, or missing owners.

The release gate is available without an application dependency:

```sh
swift run incremental-report release-manifest Release/EcosystemRelease.json
```

## Ownership and downstream locks

Incremental-Parsing owns the compatibility vocabulary and validates the
layered graph. Parser owns portable parser and generalized recovery schemas.
Grammar owns normalized grammar schemas. Engines retain their native state;
language kits retain language policy; products retain packaging and UI.

An actual distribution must add an exact immutable revision or tag for every
manifest component. Grammar-Workbench already owns a downstream compatibility
lock, boundary audit, portability matrix, signing pipeline, and artifact gate;
those product responsibilities are not duplicated here. Local development
continues to use neighboring paths, while a release checkout must use one
coordinated tag graph and must never mix local and remote copies of a SwiftPM
identity.

## Release candidate checklist

1. Validate this manifest and the downstream exact-revision lock.
2. Run every component's tests against the same source graph.
3. Run PL/0 and Pascal conformance and product campaigns.
4. Compare ModEdit, Grammar-REPL, and Grammar-Workbench evidence.
5. Gate incremental-versus-clean correctness before timing or reuse targets.
6. Build platform artifacts and run Workbench portability and signing gates.
7. Tag foundations before engines, engines before tooling and language kits,
   and products last.
8. Rebuild from tags in a clean checkout before publishing release notes.

## Remaining distribution work

Phase 31 supplies the shared release contract; it does not publish repositories,
create tags, rewrite development manifests to remote URLs, sign applications,
or upload artifacts. Those actions require an explicit release version and
distribution authorization. Experimental components remain visible in the
manifest rather than being silently presented as stable.
