# DOT and CSS providers

Phase 36 completes the initially reserved permanent language-kit set with
independent Graphviz DOT and CSS providers.

## Shared structural recovery

Parser now owns `BalancedDelimiterRecovery`, a token-neutral validator that
publishes canonical diagnostics and insertion/deletion repairs for nested
delimiter pairs. DOT and CSS consume this facility with their native lexer
token identities. Neither kit carries another generic delimiter cache or
recovery implementation.

## DOT LanguageKit

`DOT-LanguageKit` uses Lexer's grammar-driven restart-and-converge tokenizer.
Its structural pass validates `graph`/`digraph` headers, graph and attribute
delimiters, and directed versus undirected edge operators. It publishes
semantic tokens, exact source ranges, incremental lexical evidence, and
portable recovery edits through the unified provider API.

The current provider targets practical DOT authoring. It does not yet build a
complete typed graph model or render through Graphviz.

## CSS LanguageKit

`CSS-LanguageKit` uses the same lexical and provider substrate. Its structural
pass validates braces, parentheses, brackets, and common missing-colon errors
inside declaration blocks. The lexical vocabulary covers comments, strings,
at-keywords, hashes, identifiers, custom properties, numeric dimensions, and
the common selector/declaration operators.

This is a practical editor grammar rather than a complete implementation of
all evolving CSS specifications. Typed values, selector semantics, nested-rule
disambiguation, and browser-specific compatibility diagnostics remain future
language-kit work.

## ModEdit distribution

DOT and CSS are now active `bundledPermanent` providers owned by their own
packages. ModEdit contains only presentation formats, document-type metadata,
and thin adapters. All four independent bundled kits—JSON, Grammar, DOT, and
CSS—share the same document lifecycle as ModEdit-owned HTML, Markdown, and
LaTeX providers.
