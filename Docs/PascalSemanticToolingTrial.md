# Pascal semantic and tooling trial

Phase 28 uses Pascal as the second independent adopter of the shared semantic
and tooling boundary. The language kit, rather than Language-Tooling or an
editor, owns Pascal's declaration and reference rules.

The first semantic slice recognizes program, constant, type, variable,
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

## Deliberate boundary

This is a compact semantic trial, not a complete Pascal implementation. It
currently uses one file scope. Nested procedure/function scopes, formal
parameters, record fields, predefined environments, full type checking,
formatting, compilation, execution, and rename presentation remain later
Pascal-owned increments. The trial demonstrates that these policies can be
added without duplicating the shared tooling query machinery.
