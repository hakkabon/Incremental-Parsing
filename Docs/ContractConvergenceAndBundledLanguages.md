# Contract convergence and bundled languages

Phase 34 closes two architectural gaps: language kits now cross parser and
consumer boundaries using the same source, diagnostic, syntax, and recovery
contracts; and ModEdit's permanent language set is described independently of
the implementations that provide it.

## Canonical contracts

`Incremental-Parsing` remains the owner of source snapshots, changes, ranges,
positions, diagnostics, and parser-neutral recovery actions. Diagnostics have
stable identities, ordered expected-token lists, and relocation that preserves
identity. `Parser` aliases this diagnostic rather than defining another one and
projects its richer engine recovery actions into the canonical recovery form.

Parser engines may retain native state and rich token values internally. Those
details stop at the provider boundary. Language kits publish `SourceRange`,
`ParseDiagnostic`, generic syntax products, and canonical recovery identities.
Pascal now adopts these contracts directly. PL/0 accepts the canonical
`SourceSnapshot` and exact `SourceChange` at its session entry point; its older
snapshot is an internal compatibility projection rather than a provider API.

## Bundling is not ownership

`ModEdit-Bundled-Languages` owns only distribution policy. Its catalog records
which providers ModEdit ships permanently and who owns their implementation.
ModEdit validates its standard provider registry against the active catalog.

- HTML, Markdown, and LaTeX are active ModEdit-owned providers.
- JSON, Grammar notation, Graphviz DOT, and CSS are planned independent
  language-kit packages.
- PL/0 and Pascal remain independently installed external kits.

The planned kits are not implemented by this phase. When each is ready,
changing its catalog availability to `active` and wiring its provider into
ModEdit should be a distribution change, not a parser integration project.

## Dependency direction

The intended direction is:

```text
Incremental-Parsing <- Parser / Lexer / engines
                    <- Language-Tooling
                    <- language kits
                    <- ModEdit-Bundled-Languages catalog
                    <- ModEdit
```

No parser, lexer, grammar, tooling, or language-kit package depends on ModEdit.
The catalog does not contain grammars or implementation logic and does not make
independent kits part of ModEdit's source tree.

## Remaining convergence work

PL/0 still carries compatibility types behind its canonical session entry, and
Pascal's generalized recovery search retains a token-index edit model inside
the engine adapter. These are deliberate internal bridges. A later phase can
remove them once all engines expose ordered repairs with stable token identity;
they must not escape into new provider APIs.
