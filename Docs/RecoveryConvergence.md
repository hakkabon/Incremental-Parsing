# Recovery convergence

Phase 38 closes the coordinate mismatch between parser recovery, language
providers, and composite documents.

## Portable recovery steps

Parser engines may continue to search and replay repairs using token indices
and stable token identities. Before crossing the language-provider boundary,
each repair is now projected to a `LanguageProviderRecoveryAction` expressed
in UTF-16 source coordinates. Insert, delete, replace, and skip are represented
without requiring the consumer to reconstruct an engine's token stream.

`LanguageProviderRecoveryEdit` retains the repair cost, expected terminals,
and its optional diagnostic identity. Provider diagnostics now expose stable
identities as well. `RecoveryPlan.languageProviderEdits` is the canonical
projection from the shared parser-neutral recovery algebra.

The language-provider contract is schema version 3. This is an intentional
breaking correction of the schema-2 token-index recovery representation.

## Embedded recovery

Language-Tooling relocates child recovery actions by the embedded content
offset, just as it relocates child diagnostics and syntax tokens. Child
diagnostic identities are namespaced by stable region ID; recovery links use
the same namespace. Host and child repairs can therefore coexist in one
analysis without ambiguous coordinates or identities.

## Adoption

PL/0, Pascal, JSON, Grammar, CSS, and DOT providers now project their repairs
before publishing them. CSS and DOT preserve the complete shared delimiter-recovery
algebra, including replacement and skip actions. Parser-owned token-coordinate
edits remain valid internal implementation details.

## Remaining work

This phase converges recovery evidence, not edit application policy. Consumers
must still ask before applying repairs and resolve conflicts when several
repairs overlap. Recursive embedding and recovery-plan ranking across sibling
regions remain future work.
