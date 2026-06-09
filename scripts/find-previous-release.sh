#!/usr/bin/env bash
# Resolve the anchor tag for the release body's "Changes since {anchor}" section.
#
# Given the release tag being published and the set of existing releases,
# returns the anchor tag and a kind label. Pure function: source_branch
# handling is done at render time in compose-release-body.sh, not here.
#
# Inputs (env):
#   GITHUB_REPOSITORY    For gh API calls.
#   GH_TOKEN             For gh API calls. Workflow's github.token is sufficient.
#
# Outputs (stdout, KEY=VALUE, intended for $GITHUB_OUTPUT):
#   anchor_tag=v9.1.2    (empty when anchor_kind=none)
#   anchor_kind=stable|none
#
# Exit codes:
#   0  success
#   3  missing input or internal error

set -euo pipefail

err() { printf '::error::%s\n' "$*" >&2; }

# Override hook for tests. Returns the unsorted set of release tags on stdout.
# SemVer sorting happens in select_anchor, not here.
lookup_releases() {
    gh release list --repo "${GITHUB_REPOSITORY}" --limit 100 \
        --json tagName --jq '.[].tagName'
}

# Parse a stable tag (vM.N.P) into M N P components.
# Returns non-zero on a non-stable tag.
parse_stable_tag() {
    local tag="$1"
    if [[ "$tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        printf '%s %s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
        return 0
    fi
    return 1
}

# Parse the release tag being published. Sets globals REQ_M, REQ_N, REQ_P,
# REQ_IS_PRERELEASE.
parse_release_tag() {
    local tag="$1"
    if [[ "$tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)-(alpha|beta)(\.[0-9a-zA-Z.]+)?$ ]]; then
        REQ_M="${BASH_REMATCH[1]}"
        REQ_N="${BASH_REMATCH[2]}"
        REQ_P="${BASH_REMATCH[3]}"
        REQ_IS_PRERELEASE=true
        return 0
    elif [[ "$tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        REQ_M="${BASH_REMATCH[1]}"
        REQ_N="${BASH_REMATCH[2]}"
        REQ_P="${BASH_REMATCH[3]}"
        REQ_IS_PRERELEASE=false
        return 0
    fi
    err "Invalid release tag format: '$tag'"
    return 3
}

# Select the anchor tag using rules A and B from the design spec.
# Reads REQ_M, REQ_N, REQ_P, REQ_IS_PRERELEASE set by parse_release_tag.
# Writes anchor_tag and anchor_kind to stdout as KEY=VALUE pairs.
select_anchor() {
    # Stub. Implemented in Task 2.
    printf 'anchor_tag=\n'
    printf 'anchor_kind=none\n'
}

main() {
    local tag="${1:-}"
    [ -n "$tag" ] || { err "release_tag argument required"; return 3; }
    parse_release_tag "$tag" || return $?
    select_anchor "$tag"
}

# ─── self-test harness ─────────────────────────────────────────────────────

self_test() {
    local pass=0 fail=0
    assert_equal() {
        local desc="$1" expected="$2" actual="$3"
        if [ "$expected" = "$actual" ]; then
            echo "PASS: $desc"
            pass=$((pass + 1))
        else
            echo "FAIL: $desc"
            echo "  expected: $expected"
            echo "  actual:   $actual"
            fail=$((fail + 1))
        fi
    }

    # Case 1: no prior stable releases -> kind=none
    lookup_releases() { :; }
    local out
    out=$(main "v9.2.0-alpha.260605")
    assert_equal "case 1: no prior stable -> anchor_kind=none" \
        "anchor_kind=none" \
        "$(echo "$out" | grep '^anchor_kind=')"
    assert_equal "case 1: no prior stable -> anchor_tag empty" \
        "anchor_tag=" \
        "$(echo "$out" | grep '^anchor_tag=')"

    echo
    echo "Results: $pass passed, $fail failed"
    [ "$fail" -eq 0 ]
}

if [ "${1:-}" = "--self-test" ]; then
    self_test
    exit $?
fi

main "$@"
