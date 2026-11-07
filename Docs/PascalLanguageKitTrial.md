# Pascal language-kit trial

Phase 19 validates the consolidated grammar and lexical pipeline with a second
language written outside the PL/0 implementation. The Pascal package owns its
grammar and corpus while consuming the shared Grammar, Lexer, Parser, Earley and
IncrementalParsing packages.

## Results

- The original Pascal BNF remains the basis of the kit and has been completed
  with named keywords, symbols, tokens and trivia.
- Pascal exposed the need for readable case-insensitive literals. The canonical
  lexical artifact now supports `insensitive("program")`; `GrammarDrivenLexer`
  executes it without a Pascal-specific keyword table.
- The grammar resource compiles into one validated artifact. Every significant
  lexical rule must be referenced by a production, and every production
  terminal must resolve to a lexical rule.
- The generic lexer provides lossless UTF-16 tokenization and native
  restart-and-converge reuse. It correctly distinguishes `1.25`, `1..2`, and
  `.` through maximal munch.
- The existing generalized Earley engine accepts the compact Pascal corpus,
  including the grammar's intentionally overlapping designator and expression
  forms.
- `PascalProvider` implements the Phase 17 consumer boundary without a ModEdit
  dependency. Portable front-end reports and the product campaign verify clean
  equivalence.

## Findings

The platform substantially reduces new-language boilerplate: Pascal needs no
grammar parser, scanner implementation, incremental token protocol adapters, or
host-specific analysis contract. A named token wrapper is sufficient; a large
hand-maintained token enum or macro is not required for this stage.

Two limitations remain deliberately visible. Incremental tokenization is
native, but the Pascal Earley chart currently falls back to a full rebuild
after an edit. Phase 20 now gives syntax failures shared bounded repair,
portable edits and a repaired native SPPF, but the kit does not yet project
that forest into a typed Pascal recovery CST. Those gaps remain explicit
evidence rather than being hidden by a language-specific cache or parser.

## Recommended continuation

1. Expand the corpus against a declared Pascal dialect and add externally
   sourced conformance examples.
2. Connect dependency-indexed Earley chart reuse to the actual construction
   loop, then rerun the Pascal campaign.
3. Project generalized repair provenance into a typed Pascal CST.
4. Add a small semantic layer for declarations, scopes and type names.
5. Only then add formatting and ModEdit-specific presentation adapters.
