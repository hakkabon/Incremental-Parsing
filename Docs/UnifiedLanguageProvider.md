# Unified language-provider API

Phase 17 introduces one consumer-facing contract for external language kits and
application-bundled languages. The contract belongs to `IncrementalParsing`
because it is expressed entirely in revisioned UTF-16 snapshots, diagnostics,
tokens, artifact identities, and operational evidence. It has no dependency on
ModEdit, Uniform Type Identifiers, SwiftUI, AppKit, or a parser algorithm.

## Contract

A `LanguageProvider` publishes an immutable `LanguageProviderDescriptor` and
creates one actor-isolated `LanguageProviderSession` per open document. The
descriptor declares:

- stable language ID, display name, and common file extensions;
- whether the implementation is a permanent bundled provider, an external
  language kit, or a host-defined provider; and
- explicit capabilities such as highlighting, incremental analysis,
  diagnostics, recovery, formatting, preview, semantics, compilation, and
  execution.

The session accepts a `SourceSnapshot` and an optional validated
`SourceChange`. It returns a portable `LanguageProviderAnalysis` containing
classified UTF-16 ranges, diagnostics, optional grammar/artifact identity, and
separately named operation evidence. Lexing, parsing, and semantic reuse are
never combined into one percentage.

Formatting and HTML preview are optional session operations. Calling an
unsupported operation produces `LanguageProviderError.unsupportedCapability`;
consumers should normally consult the descriptor first.

## Current providers

`PL0-LanguageKit` exports `PL0Provider` as an external-language-kit provider.
Its session retains the existing incremental language session and publishes
independent `lexing`, `parsing`, and `semantics` evidence. Batch edits remain a
safe full-analysis boundary through the established PL/0 compatibility bridge.

ModEdit's standard registry is now provider-first:

| Provider | Distribution | Services |
|---|---|---|
| PL/0 | external language kit | incremental analysis, diagnostics, recovery, formatting, semantics, compilation, execution |
| Markdown | bundled permanent | highlighting, preview |
| HTML | bundled permanent | highlighting, preview |
| LaTeX | bundled permanent | highlighting, preview |
| Plain text | bundled permanent fallback | highlighting contract with no classified spans |

The built-in providers continue to own ModEdit's existing scanners, rules, and
preview renderers. They are not converted into external packages and cannot be
accidentally displaced from `FormatRegistry.standard`. Uniform Type Identifier
matching remains a ModEdit concern layered over the neutral descriptor.

The editor's language picker enumerates providers rather than raw formats.
`DocumentFormat` remains as a compatibility and presentation layer while the
rest of ModEdit migrates incrementally; specialized PL/0 compiler and execution
views may still use the typed PL/0 adapter where the neutral result deliberately
does not expose language-specific program values.

## Pascal adoption

A Pascal language kit should implement `LanguageProvider` directly and retain
its parser/compiler state inside its session actor. ModEdit integration then
requires only a small presentation adapter for content types and theme mapping;
it should not require changes to the registry, editor picker, snapshot model,
diagnostic transport, or operational-evidence schema.
