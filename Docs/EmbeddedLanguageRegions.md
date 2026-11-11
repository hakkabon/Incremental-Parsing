# Embedded-language regions

Phase 37 adds first-class embedded-language ownership to the unified provider
contract and exercises it through ModEdit's HTML and Markdown providers.

## Contract

`EmbeddedLanguageRegion` identifies a stable region ID, its owning language,
and the UTF-16 content range inside the host document. Delimiters remain host
syntax. `LanguageProviderAnalysis` publishes ordered regions and the language-
provider contract advances to schema version 2. Providers that compose child
languages advertise the `embeddedLanguages` capability.

The new field is additive when decoding: schema-1 analysis payloads without
regions continue to decode with an empty region list.

## Composite session

Language-Tooling owns `EmbeddedLanguageProvider`. It combines a host provider,
a set of independently owned child providers, and a host-specific region
resolver. The composite session:

- retains one child session per stable region ID;
- derives a minimal child `SourceChange` from successive host revisions;
- relocates child tokens and diagnostics into host coordinates;
- gives embedded tokens precedence over overlapping host highlighting;
- preserves multiline host and child semantic tokens;
- publishes distinct `embedded.<region>.<operation>` reuse evidence.

The implementation rejects duplicate, overlapping, unknown, and out-of-bounds
regions rather than allowing ambiguous ownership.

## Initial host adoption

ModEdit's HTML provider recognizes:

- `<style>` contents as CSS;
- `<script type="application/json">` and
  `<script type="application/ld+json">` contents as JSON.

Its Markdown provider recognizes fenced regions labelled `json`, `css`, `dot`,
`graphviz`, `bnf`, `ebnf`, `wsn`, or `grammar`. The existing JSON, CSS, DOT, and
Grammar providers analyze those contents; ModEdit contains no embedded parser.

## Current boundary

Child diagnostics, recovery actions, and semantic tokens are host-relative.
Child operation evidence remains separately measurable. Recovery actions and
diagnostic identities are namespaced and relocated by the composite provider;
see [Recovery convergence](RecoveryConvergence.md). Completions, navigation,
formatting, and recursively nested embedded regions remain future work.
