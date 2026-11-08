# Product campaign

Phase 16 makes the Phase-14 measurement contract executable through real
language and product boundaries. `PL0-LanguageKit` owns one versioned campaign;
ModEdit, Grammar-REPL, and Grammar-Workbench invoke it without copying fixtures
or translating engine evidence.

## PL/0 campaign v1

`pl0-product-campaign-v1` performs one warmup and three measured iterations for
ten scenarios:

- clean accepted programs through generated LR;
- malformed full parses through reference LL recovery;
- restart-and-converge tokenization after an expression edit;
- LL region reuse and LL recovery after local edits;
- native LR stack resumption;
- native Earley chart-column and dependency-indexed fact reuse; and
- dependency-aware semantic binding reuse.

Every measured result is compared with a fresh session over the same final
source. The campaign publishes the bundled grammar artifact identity and passes
the selected producer's `IncrementalExecutionEvidence` through unchanged.
Engine-specific dimensions remain valid because the measurement contract is
open-ended; no unlike reuse units are combined.

## Product entry points

```sh
swift run --package-path ../ModEdit modedit-experiment \
  product-campaign modedit-product.json
swift run --package-path ../Grammar-REPL grammar-repl-pl0-experiment \
  product-campaign repl-product.json
swift run --package-path ../Grammar-Workbench grammar-workbench-pl0-experiment \
  product-campaign workbench-product.json

swift run incremental-report compare \
  modedit-product.json repl-product.json workbench-product.json

swift run --package-path ../ModEdit modedit-experiment \
  product-budgets pl0-product-budgets.json
swift run incremental-report gate \
  modedit-product.json pl0-product-budgets.json
```

The evidence fingerprints must agree. Timing is compared only when host,
operating system, architecture, Swift toolchain, and campaign protocol match.
`PL0_MEASUREMENT_HOST_ID` and `PL0_MEASUREMENT_SWIFT_VERSION` may provide stable
CI identities when environment discovery is unsuitable.

## Release gate

`PL0ProductCampaign.releaseBudgets` requires clean equivalence for every
scenario, disallows unexpected fallback, and applies small nonzero reuse floors
to lexer tokens, LL syntax nodes, LR parser states, and semantic nodes. The
known Earley scenario permits exactly the measured fallback count; it therefore
records the limitation without pretending that chart reuse exists. Timing
limits remain runner-specific CI policy.

The cross-front-end verification script runs both the original conformance
suite and this product campaign. A future Pascal language kit should define its
own campaign with the same API and report format; no product-specific campaign
implementation should be necessary.
