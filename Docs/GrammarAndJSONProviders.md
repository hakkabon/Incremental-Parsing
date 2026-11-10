# Grammar and JSON providers

Phase 35 activates the first independently owned language kits in ModEdit's
permanent distribution catalog.

## Grammar LanguageKit

`Grammar-LanguageKit` recognizes BNF, EBNF, WSN, and the Grammar package's
combined notation. It deliberately reuses `GrammarParser`; it does not contain
another grammar parser. Grammar owns the shared notation lexical specification,
which Lexer's restart-and-converge tokenizer executes to provide lossless
highlighting and incremental lexical evidence. Grammar's panic-mode diagnostics are projected
through the shared provider contract without printing editor diagnostics to
standard output.

The Grammar package now exposes diagnostic message, token, line, and column
data and lets library consumers disable console reporting. Reporting remains
enabled by default for existing command-line clients.

## JSON LanguageKit

`JSON-LanguageKit` uses the same shared incremental lexical machinery. Its
small structural parser validates objects, arrays, scalar values, separators,
and delimiters, and publishes bounded insertion/deletion recovery evidence.
String escapes and trailing commas are validated strictly. The provider also
publishes semantic tokens and deterministic pretty-printing.

## ModEdit adoption

Both kits are independent packages with no ModEdit dependency. ModEdit adds
only presentation formats and thin provider adapters. JSON and Grammar are now
`bundledPermanent` providers, and the distribution catalog records their
language-kit ownership. Graphviz DOT and CSS were subsequently activated by
Phase 36 as independent kits.

This establishes the activation path for future bundled kits:

1. implement and test the provider in its own package;
2. add a presentation-only ModEdit format and adapter;
3. mark the catalog entry active;
4. verify the shared document lifecycle through ModEdit.
