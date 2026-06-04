#!/usr/bin/env python3
"""
Generate Markdown release notes for the BHoM nightly-alpha release.

Diffs the current build's per-dep manifest against the previous release's
manifest and renders, per changed dep:
  - PRs merged in the range (linked, with author handle)
  - Direct commits not associated with any PR (fallback section)

For an initial publish (no previous manifest), lists every dep with its
current tip SHA so subsequent diffs have a baseline.

Inputs:
  argv[1]: path to current dep-manifest.json (required)
  argv[2]: path to previous dep-manifest.json (optional — pass an empty
           string or missing path for an initial publish)
  argv[3]: output Markdown path (defaults to release-notes-section.md)

Environment:
  GH_TOKEN: a token with read access to every dep repo's commits/PRs.
            Workflow github.token is enough for public BHoM repos; the
            BHoM App token is needed when extended to private BHE deps.

Manifest schema (version 1):
  {
    "version":      1,
    "built_at":     "ISO8601",
    "release_type": "alpha"|"beta",
    "main_branch":  "develop",
    "deps": {
      "<owner>/<repo>": { "branch": "develop", "sha": "<40-char>" },
      ...
    }
  }
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


GH_TOKEN = os.environ.get("GH_TOKEN", "")
if not GH_TOKEN:
    print("::error::GH_TOKEN env var is required", file=sys.stderr)
    sys.exit(1)


def api(path: str) -> dict | list | None:
    """Call GitHub REST API. Returns parsed JSON, or None on 4xx not-found."""
    url = f"https://api.github.com/{path.lstrip('/')}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {GH_TOKEN}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "bhom-installer-release-notes",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        if e.code in (404, 422):
            return None
        # Surface other errors but don't crash the whole publish — one dep's
        # API failure shouldn't take down the release.
        print(f"::warning::HTTP {e.code} fetching {url}: {e.reason}", file=sys.stderr)
        return None
    except (urllib.error.URLError, TimeoutError) as e:
        print(f"::warning::Network error fetching {url}: {e}", file=sys.stderr)
        return None


def short(sha: str) -> str:
    return sha[:7] if sha else ""


def render_initial_notes(curr: dict) -> str:
    deps = curr.get("deps", {})
    lines = [
        "### Initial nightly-alpha publish",
        "",
        "This is the first build under this tag. Subsequent releases will "
        "diff their dep tips against this baseline.",
        "",
        "| Repo | Branch | Tip |",
        "|---|---|---|",
    ]
    for repo in sorted(deps):
        info = deps[repo]
        lines.append(f"| {repo} | {info.get('branch', '?')} | `{short(info.get('sha', ''))}` |")
    lines.append("")
    return "\n".join(lines)


def render_dep_changes(repo: str, prev_sha: str, curr_sha: str) -> list[str]:
    """Render the section for one changed dep."""
    cmp_data = api(f"repos/{repo}/compare/{prev_sha}...{curr_sha}")
    header_range = f"`{short(prev_sha)}...{short(curr_sha)}`"

    if cmp_data is None:
        return [
            f"#### {repo} {header_range}",
            "",
            f"*Compare range not resolvable (possibly a force-push on the branch). "
            f"[See on GitHub](https://github.com/{repo}/compare/{prev_sha}...{curr_sha}).*",
            "",
        ]

    commits = cmp_data.get("commits", [])
    if not commits:
        return [
            f"#### {repo} {header_range}",
            "",
            "*No commits in range.*",
            "",
        ]

    # Collect unique PRs and any direct (non-merge, non-PR) commits.
    seen_pr_numbers: set[int] = set()
    prs: list[dict] = []
    direct: list[dict] = []

    for c in commits:
        if len(c.get("parents", [])) > 1:
            # Skip merge commits — their content is reflected via the PR.
            continue
        sha = c["sha"]
        commit_prs = api(f"repos/{repo}/commits/{sha}/pulls") or []
        merged_prs = [p for p in commit_prs if p.get("merged_at")]

        if merged_prs:
            for pr in merged_prs:
                if pr["number"] not in seen_pr_numbers:
                    seen_pr_numbers.add(pr["number"])
                    prs.append(pr)
        else:
            direct.append({
                "sha": sha,
                "message": c["commit"]["message"].split("\n", 1)[0],
                "author": c["commit"]["author"]["name"],
            })

    # Header line summarising what's in this section.
    bits: list[str] = []
    if prs:
        s = "s" if len(prs) > 1 else ""
        bits.append(f"{len(prs)} PR{s} merged")
    if direct:
        s = "s" if len(direct) > 1 else ""
        bits.append(f"{len(direct)} direct commit{s}")
    if not bits:
        # No non-merge commits, only merge commits. Should be rare.
        bits.append(f"{len(commits)} commits")

    out = [f"#### {repo} {header_range} — {', '.join(bits)}", ""]

    # Cap per-dep PR list to keep release bodies under GitHub's 125 KB limit.
    PR_CAP = 30
    for pr in prs[:PR_CAP]:
        author = (pr.get("user") or {}).get("login", "?")
        out.append(f"- [#{pr['number']}]({pr['html_url']}): {pr['title']} (@{author})")
    if len(prs) > PR_CAP:
        out.append(f"- *…and {len(prs) - PR_CAP} more.*")

    if direct:
        if prs:
            out.append("")
            out.append("*Direct commits (bypassing PR):*")
        for d in direct[:PR_CAP]:
            out.append(f"- {d['message']} ({d['author']}) `{short(d['sha'])}`")
        if len(direct) > PR_CAP:
            out.append(f"- *…and {len(direct) - PR_CAP} more.*")

    out.append("")
    return out


def render_diff_notes(prev: dict, curr: dict) -> str:
    prev_deps = prev.get("deps", {})
    curr_deps = curr.get("deps", {})
    prev_set = set(prev_deps)
    curr_set = set(curr_deps)

    changed = [
        (r, prev_deps[r]["sha"], curr_deps[r]["sha"])
        for r in sorted(prev_set & curr_set)
        if prev_deps[r]["sha"] != curr_deps[r]["sha"]
    ]
    added = sorted(curr_set - prev_set)
    removed = sorted(prev_set - curr_set)
    unchanged = sum(1 for r in prev_set & curr_set if prev_deps[r]["sha"] == curr_deps[r]["sha"])
    total = len(curr_set)

    lines = ["### Dependency changes since last nightly", ""]

    if not changed and not added and not removed:
        lines.append("*No upstream changes since the previous build.*")
        lines.append("")
        lines.append(f"*{total} of {total} deps unchanged.*")
        lines.append("")
        return "\n".join(lines)

    for repo, p_sha, c_sha in changed:
        lines.extend(render_dep_changes(repo, p_sha, c_sha))

    for repo in added:
        info = curr_deps[repo]
        lines.append(f"#### Newly included: {repo} `{short(info.get('sha', ''))}`")
        lines.append("")
        lines.append("*(No prior version to compare against.)*")
        lines.append("")

    if removed:
        lines.append("### Removed from build")
        lines.append("")
        for repo in removed:
            lines.append(f"- {repo} (was at `{short(prev_deps[repo].get('sha', ''))}`)")
        lines.append("")

    lines.append(f"*{unchanged} of {total} deps unchanged since last build.*")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: generate_release_notes.py <current.json> [<previous.json>] [<out.md>]", file=sys.stderr)
        return 2

    curr_path = sys.argv[1]
    prev_path = sys.argv[2] if len(sys.argv) > 2 else ""
    out_path = sys.argv[3] if len(sys.argv) > 3 else "release-notes-section.md"

    with open(curr_path) as f:
        curr = json.load(f)

    if prev_path and os.path.isfile(prev_path):
        with open(prev_path) as f:
            prev = json.load(f)
        body = render_diff_notes(prev, curr)
    else:
        print("::notice::No previous manifest provided — emitting initial-publish baseline")
        body = render_initial_notes(curr)

    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(body)

    print(f"::notice::Wrote {out_path} ({len(body)} chars)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
