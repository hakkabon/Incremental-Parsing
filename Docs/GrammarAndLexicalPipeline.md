# Grammar and lexical pipeline

Phase 18 consolidates grammar parsing and lexical execution without moving
language-specific definitions into `IncrementalParsing`.

## Ownership

```text
grammar source
     │
     ▼
GrammarTokenizer → GrammarParser → Grammar + LexicalSpecification
                                           │
                                           ▼
                              GrammarDrivenLexer (Lexer)
                                           │
                         ┌─────────────────┴─────────────────┐
                         ▼                                   ▼
                    clean scan                 restart and converge
                         │                                   │
                         └─────────────────┬─────────────────┘
                                           ▼
                                  typed language adapter
```

- `GrammarTokenizer` owns tokenization of grammar-definition source.
- `Grammar` owns the parser and the ordered, serializable lexical artifact.
- `Lexer` owns maximal-munch scanning, trivia retention, UTF-16 coordinates,
  diagnostics, and restart-and-converge reuse.
- A language kit owns its grammar resource, typed token/nonterminal enums,
  syntax and semantic models, and thin projections from generic lexer output.
- `IncrementalParsing` owns only the parser-neutral source, edit, evidence,
  recovery, measurement, and language-provider contracts.
- Front ends consume language providers; they do not introduce another grammar
  parser or language-kit scanner.

## Source notation

The canonical grammar notation retains the existing BNF/EBNF productions and
adds readable declarations inside the existing `lexical` scope:

```text
lexical {
    keyword BEGIN = "begin";
    token IDENTIFIER = /[A-Za-z_][A-Za-z0-9_]*/;
    symbol ASSIGN = ":=";
    trivia WHITESPACE = /\s+/;
    trivia LINE_COMMENT = lineComment("//");
    trivia BLOCK_COMMENT = blockComment("/*", "*/");
}

Program ::= BEGIN IDENTIFIER ASSIGN IDENTIFIER;
```

Legacy lexical declarations such as `IDENTIFIER = /.../;` remain accepted as
significant token rules. `keyword`, `token`, `symbol`, and `trivia` are
contextual inside a lexical block, so existing grammars may still use those
words as production names.

Matching uses maximal munch. Rule priority resolves equal-length keyword,
symbol, token, and trivia matches; declaration order is the stable final
tie-break. Structured comment declarations avoid duplicating assertion-heavy
regular expressions and expose bounded unterminated-comment diagnostics.

## Adoption

The PL/0 kit now compiles its bundled grammar with `GrammarParser` and scans the
result with `GrammarDrivenLexer`. Its public lexer and incremental tokenizer are
compatibility projections, not independent implementations. Grammar-Workbench's
canonical grammar path lowers the same lexical artifact into its current
runtime representation; its richer Yacc-style reader remains a compatibility
input format. Grammar-REPL and ModEdit consume the resulting PL/0 provider
without owning grammar or lexer rules.

The generic runtime removes more boilerplate than a language-specific macro:
new kits do not need scanner rules or incremental-lexer conformances. A future
macro or build-time generator may still derive typed token bindings and validate
them at compile time, but it must consume this artifact rather than establish a
second grammar dialect.
