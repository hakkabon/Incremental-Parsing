# PL/0 surface reduction

Phase 32 begins converting PL0-LanguageKit from the historical platform
incubator into a human-readable language package.

## Ownership changes

The 640-line `LanguageExperimentProtocol` and its tests moved intact to
Language-Tooling. It is language-neutral infrastructure: experiment bundles,
artifact identities, portable recovery and reuse evidence, validation, and
stable fingerprints. PL/0 now consumes that product like any other kit.

The PL/0-owned Grammar-Workbench process transport and hot-reload bridge were
removed. No workspace product consumed that reverse-facing API; hosts already
consume PL/0 through the unified language-provider boundary.

The parallel `PL0LSPAdapter` was also removed. `PL0ProviderSession` now carries
both parser and semantic diagnostics and remains the only document/tooling
session. The provider already supplies completion, definition, references,
hover, semantic tokens, formatting, and incremental analysis.

## Size result

Before Phase 32, PL0-LanguageKit contained 6,371 production and 2,558 test lines
of Swift. The initial consolidation leaves 5,094 production and 2,132 test
lines: 1,277 production lines (20.0%) and 426 test lines (16.7%) removed from
the language-kit repository. The generic protocol remains tested in its new
owner rather than being discarded.

The remaining difference from Pascal is now dominated by real capability:
PL/0 includes a compiler and VM, formatter, recovered CST, LL/LR/Earley and
ecosystem comparison paths, grammar hot reload, and mature mutation campaigns.
Those are kept explicit rather than hidden behind macros.

## Compatibility decision

The old `LanguageExperimentProtocol` product exported by PL0-LanguageKit and
the PL/0-specific LSP and Workbench bridge APIs are intentionally removed.
Consumers import `LanguageExperimentProtocol` from Language-Tooling and use
`PL0Provider`/`PL0ProviderSession`. This is a source migration, not a silent
compatibility shim that would preserve the same ownership mistake.

## Next reduction boundary

The next safe reductions require shared mechanisms rather than deletion:

- a generic engine-registration and observation harness for the PL/0 and
  future Pascal multi-engine campaigns;
- shared campaign projection helpers in LanguageToolingTesting; and
- eventual replacement of PL/0 compatibility source/diagnostic types once the
  recovered CST can use the shared contracts directly.

Compiler, VM, binding, recovery, and formatting policy remain language-owned.
