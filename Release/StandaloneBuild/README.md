# Standalone SwiftPM release

This release replaces 105 sibling-checkout dependencies across 20 package
manifests with versioned GitHub dependencies. [candidate.json](candidate.json)
records the exact commits, tags, and dependency order. The patches show what
changed, including the ModEdit and Grammar-Workbench lockfiles. The bundles
preserve the release commits and require their recorded base commits.

ModEdit resolves Railroad 0.1.0 at `6e0ce6837df5a0389e558f23b81713722de58999`.
Grammar-Workbench's release also uses the LR runtime's original-token recovery
edits and detects notation when macOS aliases grammar content types.

## Verify from the public tags

Run on macOS with a Swift toolchain that supports the consumer manifests and
a system Graphviz installation visible to pkg-config. Grammar-Workbench also
downloads the Swift-Layout binary artifact.

```sh
./verify-published.sh 0.38.4 0.17.1 1.10.1
```

The script clones the three consumers into an isolated directory, resolves the
published package graph, and runs their suites. See
[Verification](Verification.md) for the release results.

## Edit multiple packages locally

After resolving the released graph, opt individual packages into a local
checkout from the consuming repository.

```sh
swift package edit grammar --path /absolute/path/to/Grammar
swift test
swift package unedit grammar
```

Use the SwiftPM identity in `Package.resolved`. For a coordinated cross-package
change, edit the affected dependencies in the consumer you are using to test
it.
