# Shared language tooling foundation

Phase 23 introduces `Language-Tooling` as a sibling package above
`IncrementalParsing`. It removes editor-neutral mechanisms from language kits
without moving language policy into the parsing foundation.

```text
ModEdit / Grammar tools / LSP transports
                    |
                    v
             language kits
                    |
                    v
            Language-Tooling
                    |
                    v
          IncrementalParsing
```

`LanguageTooling` owns UTF-16 coordinate mapping, portable completion and
navigation values, a language-neutral semantic graph and its queries,
deterministic semantic-token encoding, and an extended language-provider
session. `LanguageToolingFormatting` owns only indentation and whitespace
mechanics. `LanguageToolingTesting` provides reusable graph and token-stream
validation.

Language kits continue to own grammar and lexical artifacts, syntax and
recovery projections, binding and type rules, formatting decisions, semantic
classifications, and compiler behavior. Hosts continue to own protocol
transport, document orchestration, UI, and visualization. Consequently the new
package does not depend on PL/0, Pascal, ModEdit, or any parser engine.

## First adopters

PL/0 projects its existing symbols, references, and lexical scopes into
`ToolingSemanticIndex`. Its LSP adapter now delegates visibility, definition,
references, coordinate conversion, completion deduplication, and semantic-token
encoding to shared mechanisms. Its formatter retains PL/0 policy while using
the shared formatting writer.

Pascal adopts the same `LanguageToolingProvider` boundary independently. Its
current session derives keyword completion from the compiled grammar artifact
and encodes lexical semantic tokens. Navigation and semantic completion remain
unsupported until Pascal has a native semantic model; the shared layer does not
invent language meaning.

## Dependency rule

`IncrementalParsing` remains the lowest portable contract package and must not
depend on `Language-Tooling`. Parser packages likewise remain independent of
language tooling and ModEdit. A future reusable mechanism belongs in
`Language-Tooling` only after at least two language kits need it; otherwise it
stays with the language that owns the policy.
