# Standalone release verification

The SwiftPM release preflight passed for all 25 package manifests. All 20
changes were staged as Git bundles and reviewed as patches against their
recorded base revisions.

The consumer tests ran on macOS with Swift 6.1.2 in fresh GitHub clones at the
exact release commits. SwiftPM resolved every dependency directly from
published GitHub tags, using isolated caches and no sibling package checkouts
or Git URL rewrites. Each ecosystem pin was checked for both the intended
version and commit.

| Package | Tag | Tests passed |
| --- | --- | ---: |
| ModEdit | 0.38.4 | 158 |
| Grammar-REPL | 0.17.1 | 46 |
| Grammar-Workbench | 1.10.1 | 447 |
| Pascal-LanguageKit | 0.8.1 | 10 |

ModEdit's lockfile resolves Railroad 0.1.0 at
`6e0ce6837df5a0389e558f23b81713722de58999`. The public Swift-Layout binary
archive matched its declared checksum. The verification script disables
SwiftPM's keychain lookup for public artifact downloads.

The rebuilt ModEdit, Grammar-REPL, and Grammar-Workbench PL/0 campaigns
reported equivalent evidence with fingerprint `8ca91fd31a03c6a2`.

All 25 tag revisions in the release index were verified directly on GitHub.
