# Phase 33 — Language-kit substrate extraction

Phase 33 makes language kits describe languages rather than host a second
parsing platform.

## Ownership

- **Incremental-Parsing** owns UTF-16 source ranges and positions, canonical
  snapshots and changes, and the compact embedded-edit compatibility envelope.
- **Parser** owns generic stable syntax nodes, concrete terminals and trees,
  diagnostics, recovery records, parser descriptors, inputs, outputs, and
  reuse metrics.
- **Lexer** owns grammar-driven language tokenization through
  `GrammarLanguageTokenizer`; language kits provide typed projections only.
- **LL-Parsing** owns the region-cache relocation conformances for shared
  parser products.
- **PL0-LanguageKit** owns PL/0 grammar bindings, tokens, parser decisions,
  semantic rules, formatting, compilation, execution and provider adaptation.

## PL/0 result

The formerly generic-looking `SourceModel`, `ConcreteSyntaxTree`,
`Diagnostics`, `ParserContract`, and `SyntaxNode` implementations have
left PL0-LanguageKit. The remaining language-specific specializations live in
`PL0ParseProducts.swift`. Consumer and engine adapters were renamed with a
`PL0` prefix, and a test rejects any future implementation filename that
does not declare PL/0 ownership.

Production Swift in PL0-LanguageKit is reduced from 5,094 lines after Phase 32
to 4,346 lines in Phase 33. More importantly, the extracted types are now
available to every language kit rather than merely hidden behind PL/0 aliases.

Pascal adopts Lexer's same `GrammarLanguageTokenizer` facade in this phase,
providing independent reuse evidence for the first extracted substrate.

## Compatibility

PL/0's existing public spellings remain as type aliases to shared generic
products where practical. The compact snapshot carrying edit metadata is
explicitly documented as a compatibility envelope; new integrations should
continue to prefer canonical `SourceSnapshot` plus `SourceChange`.
