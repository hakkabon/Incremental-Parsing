# Live Earley incrementality

Phase 25 connects Earley-Parser's dependency-indexed chart arena to its real
scanner, predictor, completer, BSR, and SPPF construction path.

`EarleyIncrementalSession` owns one grammar-bound document runtime. Language
kits pass their stable token identities with a `TokenStream`. The session keeps
the chart columns and BSR contributions through the unchanged token prefix,
invalidates dependent item facts from the first changed token, and reconstructs
only the remaining suffix. Forest extraction runs over the combined retained
and rebuilt BSR set.

The shared operational evidence separates:

- retained and rebuilt `chartColumns`;
- dependency-retained, removed, and rebuilt `chartFacts`; and
- stable versus regenerated `tokens`.

PL/0 now replaces its disclosed full-chart fallback with the native session and
checks every incremental forest against a clean Earley parse. Pascal provides a
second independent adopter using its own grammar-derived lexer identities.
Pascal keeps generalized repair search as an explicit clean fallback when the
live recognizer cannot accept malformed input.

The implementation deliberately reuses only a contiguous prefix. A converged
suffix can have shifted token positions, item origins, BSR extents, and SPPF
node identities. Reusing that suffix requires a future relocation contract;
Phase 25 does not overstate such reuse.
