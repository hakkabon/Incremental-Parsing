# Productization and measurement

Phase 14 turns the incremental contracts into an operational product boundary.
It does not move benchmark cases or parser algorithms into this package.
Language kits own representative edit scenarios; engine packages own native
reuse state; front ends run or display the resulting portable report.

## Measurement flow

```text
language-kit scenarios + engine/session
                 |
                 v
     IncrementalMeasurementRunner
       | correctness against clean run
       | IncrementalExecutionEvidence
       | monotonic elapsed time
       v
    IncrementalMeasurementReport
       |-- host-independent evidence fingerprint
       |-- host-qualified measurement fingerprint
       |-- per-scenario summaries
       `-- independently evaluated quality budgets
```

The runner sorts scenarios by stable ID, performs unrecorded warmups, and then
records the requested number of iterations. Each operation returns its existing
`IncrementalExecutionEvidence` and states whether its observable result matched
a clean run. The report keeps every raw sample; summaries are derived and
verified during JSON decoding rather than trusted as supplied data.

## Honest comparison boundaries

Correctness and reuse observations can be compared across front ends and hosts.
Their fingerprint covers protocol, artifact identity, scenarios, clean-run
equivalence, execution strategy, fallback reason, and every reuse dimension.
It excludes durations and host identity.

Timing is comparable only when `isTimingComparable(to:)` succeeds. The
measurement fingerprint covers the evidence fingerprint, exact environment
identity, and raw nanosecond samples. It is an integrity identity, not a claim
that a workstation is a controlled laboratory.

Reuse remains dimensional. A report never combines tokens, stacks, charts,
forest nodes, semantic nodes, and IR nodes into a universal percentage. Each
scenario summary totals the native units supplied by its engine and computes a
ratio only within that dimension.

## Quality gates

`IncrementalMeasurementBudget` can require:

- equivalence with clean execution;
- a maximum fallback count;
- maximum median and nearest-rank p95 durations; and
- minimum reuse ratios for explicitly named dimensions.

Budgets are evaluated after measurement and are not embedded in the report.
That permits a developer laptop, CI, and a release workflow to use different
timing thresholds against the same raw artifact. Correctness should normally be
mandatory everywhere. Missing reuse evidence fails a requested reuse budget
instead of being interpreted as zero or success.

## Adoption by the ecosystem

1. `PL0-LanguageKit` defines the first product campaign from its accepted,
   recovery, and edit corpora. A future Pascal kit should reuse the same shape;
   the effort required to author those scenarios is itself platform feedback.
2. Lexer, LL, LR, Earley, RNGLR, and Compiler continue publishing their native
   `IncrementalExecutionEvidence`. The kit combines no counts; it passes each
   measured operation through unchanged.
3. ModEdit, Grammar-REPL, and Grammar-Workbench run the same kit campaign. Their
   evidence fingerprints must agree. Timing comparisons are allowed only for
   reports whose environment and protocol identities match.
4. Grammar-Workbench may archive and visualize reports, but the verified JSON
   remains usable without that application.
5. Release CI should store the raw report, enforce clean equivalence and reuse
   floors on every host, and enforce timing budgets only on stable runners.

The `incremental-report` executable supplies the non-UI release surface. Its
`verify` command recalculates summaries and fingerprints, `compare` requires
host-independent evidence fingerprints to agree and reports whether timing is
comparable, and `gate` evaluates a JSON array of measurement budgets.

This leaves the dependency direction intact: parser packages do not depend on
ModEdit, and the shared foundation does not acquire language or UI knowledge.

Phase 16 implements these adoption points for PL/0. See
[Product campaign](ProductCampaign.md) for the scenario matrix, product entry
points, and release-gate policy.
