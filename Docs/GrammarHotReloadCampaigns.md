# Grammar hot-reload campaigns

Phase 27 turns grammar replacement into a revisioned, measurable campaign
rather than a collection of isolated transition tests.

`GrammarHotReloadCampaignRunner` is notation- and parser-independent. Each
candidate declares its source artifact fingerprint, optional target
fingerprint, retained document revision, and whether activation is expected.
The runner verifies that:

- candidates form one continuous artifact chain;
- activation agrees with the scenario expectation;
- an activated artifact has the declared target fingerprint;
- activated results are equivalent to a clean target run; and
- rejected compilation changes neither the active grammar nor the retained
  document revision.

Reports are deterministic, Codable, and carry engine-owned
`IncrementalExecutionEvidence` without translating reuse dimensions.

## PL/0 campaign

`pl0-grammar-hot-reload-v1` executes four sequential cases:

1. a production-only change that retains the lexical cache;
2. a lexical-rule change that deliberately retokenizes;
3. a simultaneous grammar and source revision accepted by the new grammar;
4. an invalid replacement that preserves the preceding grammar and document.

Every activated revision runs the directly linked parser ecosystem and is
compared with a fresh session over the same grammar artifact and document.
The lexical transition uses Lexer's real `GrammarIncrementalTokenizer`, so its
token and `grammarProductions` measurements come from the owning engine.

ModEdit, Grammar-REPL, and Grammar-Workbench expose the same campaign:

```sh
swift run --package-path ../ModEdit modedit-experiment grammar-campaign modedit-grammar.json
swift run --package-path ../Grammar-REPL grammar-repl-pl0-experiment grammar-campaign repl-grammar.json
swift run --package-path ../Grammar-Workbench grammar-workbench-pl0-experiment grammar-campaign workbench-grammar.json
```

The current campaign rebuilds parser sessions after an artifact change and
uses clean equivalence as the correctness gate. It does not claim cross-grammar
LR, Earley, or RNGLR live-state reuse where stable generated-state mappings are
not yet available.
