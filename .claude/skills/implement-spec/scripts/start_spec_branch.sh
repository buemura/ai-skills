#!/usr/bin/env bash
# Create a branch for implementing a spec.
#
#   start_spec_branch.sh docs/specs/0003-rate-limit-public-api.md
#   start_spec_branch.sh docs/specs/0003-rate-limit-public-api.md --base develop
#
# Verifies the working tree is clean, branches from an up-to-date base, and
# prints the new branch name.

set -euo pipefail

base="main"
spec=""

usage() {
  cat <<'USAGE'
Usage: start_spec_branch.sh <spec-file> [--base <branch>]

Creates and checks out spec/NNNN-slug, branched from an up-to-date base.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--base) base="${2:?--base needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*)        echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)         spec="$1"; shift ;;
  esac
done

if [ -z "$spec" ]; then
  echo "Error: a spec file is required." >&2
  usage >&2
  exit 2
fi

if [ ! -f "$spec" ]; then
  echo "Error: no such file: $spec" >&2
  exit 1
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Error: not inside a git repository." >&2
  exit 1
}

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or set aside your changes first:" >&2
  git status --short >&2
  exit 1
fi

stem="$(basename "$spec" .md)"
case "$stem" in
  [0-9][0-9][0-9][0-9]-*) ;;
  *) echo "Error: spec filename must look like NNNN-title.md (got: $stem)" >&2; exit 2 ;;
esac

branch="spec/$stem"

if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Error: branch $branch already exists. Check it out, or delete it if it's stale." >&2
  exit 1
fi

# Prefer branching from the remote base so the branch starts from what CI will merge into.
start="$base"
if git remote get-url origin >/dev/null 2>&1; then
  git fetch --quiet origin "$base" 2>/dev/null || true
  if git show-ref --verify --quiet "refs/remotes/origin/$base"; then
    start="origin/$base"
  fi
fi

if ! git rev-parse --verify --quiet "$start" >/dev/null; then
  echo "Error: base branch '$base' not found locally or on origin." >&2
  exit 1
fi

git checkout --quiet -b "$branch" "$start"

echo "$branch"
echo "  branched from: $start" >&2