#!/usr/bin/env bash
# Compose the release body for the publish-alpha workflow job.
#
# Reads inputs from environment variables and writes the final body to
# release-body.md in the current working directory. The body is composed
# of two parts:
#   1. A short preamble (this script) with build provenance and a link
#      to the diff base release.
#   2. The dependency-change section produced by generate_release_notes.py
#      and read from release-notes-section.md.
#
# Required environment:
#   GITHUB_SERVER_URL    Provided by GitHub Actions.
#   GITHUB_REPOSITORY    Provided by GitHub Actions.
#   GITHUB_RUN_ID        Provided by GitHub Actions.
#   GITHUB_SHA           Provided by GitHub Actions.
#   GITHUB_EVENT_NAME    Provided by GitHub Actions.
#   INSTALL_TEST_RESULT  'success', 'failure', 'skipped', or 'cancelled'.
#   PREV_TAG             Prior alpha release tag for the diff base, or
#                        empty string if no prior release exists.
#
# Required local file:
#   release-notes-section.md  Output from generate_release_notes.py.
#
# Output:
#   release-body.md           Final body, ready for softprops/action-gh-release.
set -eu

run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

if [ "$INSTALL_TEST_RESULT" = "success" ]; then
    test_status="Passed install and uninstall smoke tests on windows-2022 and windows-2025."
else
    test_status="Smoke test result: \`$INSTALL_TEST_RESULT\`. See [run logs]($run_url) for details. This build is provided for diagnostic and local testing only and should not be promoted to users."
fi

if [ -n "$PREV_TAG" ]; then
    diff_note="Changes are computed against [\`$PREV_TAG\`](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/releases/tag/${PREV_TAG})."
else
    diff_note="No prior alpha release was found, so this build is published as an initial baseline."
fi

cat >release-body.md <<EOF
Pre-release build of the BHoM installer produced by the alpha CI pipeline. See the build provenance below before installing.

### Build provenance

| Field | Value |
|---|---|
| Build | [#${GITHUB_RUN_ID}]($run_url) |
| Commit | \`${GITHUB_SHA}\` |
| Triggered by | \`${GITHUB_EVENT_NAME}\` |
| Test status | $test_status |

### Changes

$diff_note

EOF
cat release-notes-section.md >> release-body.md

echo ""
echo "=== Release body preview (first 80 lines) ==="
head -80 release-body.md
