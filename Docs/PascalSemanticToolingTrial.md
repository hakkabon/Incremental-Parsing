# Pascal semantic and tooling trial

Phase 28 uses Pascal as the second independent adopter of the shared semantic
and tooling boundary. The language kit, rather than Language-Tooling or an
editor, owns Pascal's declaration and reference rules.

The semantic slice recognizes program, constant, type, variable, parameter,
procedure, and function declarations case-insensitively from Pascal's stable
grammar-derived tokens. Declaration token identities become stable symbol IDs.
References carry their lexer token identity and read, write, call, or type role.
This allows literal edits and relocated suffixes to retain semantic identity
without tying the model to source offsets.

`PascalSemanticModel` projects into `ToolingSemanticIndex`, which supplies the
language-neutral algorithms for:

- visible-symbol and keyword completion;
- go-to-definition;
- references including the declaration;
- hover descriptions; and
- declaration-aware semantic token encoding.

The provider publishes semantic diagnostics and independent `semanticNodes`
evidence alongside lexing and parsing evidence. Pascal's product campaign v3
adds a clean-validated semantic-reuse scenario.

## Extended scoped tooling trial

Pascal now projects file and nested routine scopes into the existing shared
`ToolingSemanticIndex`. Value and `var` parameters have declaration identities
and parameter classification. Inner routines capture surrounding declarations;
case-insensitive shadowing changes definition, references, hover, and completion
consistently. Duplicate declarations are diagnosed within their declaring scope.
Function result assignments are writes, while recursive invocations are calls.
Compound statements and case branches do not create routine scopes, and record
`END` tokens do not terminate the surrounding declaration region.

`PascalConformanceCorpus.scopedTooling` supplies the common accepted example.
The v4 product campaign adds a shadowing-declaration edit. Regression tests also
compare edited binding targets and semantic tokens with clean analysis, check
scope isolation through the provider API, and verify routine identities and
UTF-16 locations after a prefix edit containing an emoji. A missing routine
heading semicolon retains tooling, and inserting it clears recovery evidence.
Incomplete bodies keep parameters visible at the end of the document.

The extension remains in Pascal-LanguageKit. Grammar, GrammarDrivenLexer,
Earley, recovery search, and the language-neutral tooling queries are reused.
No grammar, lexical rule, or parser-engine implementation is duplicated.

## Deliberate boundary

This is a compact semantic trial, not a complete Pascal implementation. Record
fields, enumeration members, bindings inside higher-order parameter signatures,
predefined environments, declaration-order validation, full type checking,
formatting, compilation, execution, and rename presentation remain later
Pascal-owned increments. Unresolved identifiers are not diagnosed yet.

Semantic analysis currently recomputes the projection on every revision. Its
reuse evidence measures retained symbol/binding identities rather than avoided
work. Reference reuse now requires the same token identity, target declaration,
and reference role; edits that change shadowing correctly rebuild the binding.
The next useful trial is a declared small dialect with predefined types and
unresolved-name/type diagnostics, exercised through these same provider queries.
