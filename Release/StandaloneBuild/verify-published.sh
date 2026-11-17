#!/bin/sh
# Run after the consumer branches point to the release manifests and the
# dependency tags are published. Optional arguments select consumer refs.
set -eu

# Resolve GitHub URLs directly, regardless of workstation Git rewrites.
unset GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0

if [ "$#" -gt 3 ]; then
    echo "Usage: $0 [ModEdit ref [Grammar-REPL ref [Grammar-Workbench ref]]]" >&2
    exit 2
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/standalone-swiftpm.XXXXXX")
echo "Builds and logs: $scratch"
mkdir -p "$scratch/config" "$scratch/security"

verify() (
    name=$1
    ref=$2
    mkdir "$scratch/$name"
    checkout=$scratch/$name/checkout
    git clone --quiet "https://github.com/hakkabon/$name.git" "$checkout"
    git -C "$checkout" checkout --quiet --detach "$ref"
    cd "$checkout"
    swift package --cache-path "$scratch/cache" --config-path "$scratch/config" \
        --security-path "$scratch/security" --disable-keychain resolve
    swift test --cache-path "$scratch/cache" --config-path "$scratch/config" \
        --security-path "$scratch/security" --disable-keychain
)

verify ModEdit "${1:-origin/HEAD}" > "$scratch/ModEdit.log" 2>&1
verify Grammar-REPL "${2:-origin/HEAD}" > "$scratch/Grammar-REPL.log" 2>&1
verify Grammar-Workbench "${3:-origin/HEAD}" > "$scratch/Grammar-Workbench.log" 2>&1
echo "All three standalone suites passed."
