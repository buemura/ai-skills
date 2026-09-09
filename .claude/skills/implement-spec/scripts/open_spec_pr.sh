#!/usr/bin/env bash
# Push the current spec branch and open a PR against the base branch.
#
#   open_spec_pr.sh docs/specs/0003-rate-limit-public-api.md --body-file /tmp/pr-body.md
#   open_spec_pr.sh docs/specs/0003-rate-limit-public-api.md --base develop --draft
#
# Falls back to printing a compare URL when `gh` is unavailable.

set -euo pipefail

base="main"
spec=""
body_file=""
draft=""

usage() {
  cat <<'USAGE'
Usage: open_spec_pr.sh <spec-file> [--base <branch>] [--body-file <path>] [--draft]

Pushes the current branch to origin and opens a PR against <base> (default main).
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--base)      base="${2:?--base needs a value}"; shift 2 ;;
    -f|--body-file) body_file="${2:?--body-file needs a value}"; shift 2 ;;
    -d|--draft)     draft="--draft"; shift ;;
    -h|--help)      usage; exit 0 ;;
    -*)             echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)              spec="$1"; shift ;;
  esac
done

if [ -z "$spec" ] || [ ! -f "$spec" ]; then
  echo "Error: a valid spec file is required." >&2
  usage >&2
  exit 2
fi

branch="$(git branch --show-current)"

if [ -z "$branch" ]; then
  echo "Error: detached HEAD — check out a branch first." >&2
  exit 1
fi

if [ "$branch" = "$base" ]; then
  echo "Error: refusing to open a PR from '$base' into itself. You are on the base branch." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: uncommitted changes. Commit them before opening the PR:" >&2
  git status --short >&2
  exit 1
fi

# Title: the spec's frontmatter title, prefixed with its number.
num="$(basename "$spec" .md | cut -d- -f1)"
title="$(sed -nE '1,/^---$/{ s/^title:[[:space:]]*//p; }' "$spec" | head -1)"
if [ -z "$title" ]; then
  title="$(basename "$spec" .md | cut -d- -f2- | tr '-' ' ')"
fi
title="$num — $title"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Error: no 'origin' remote configured." >&2
  exit 1
fi

echo "Pushing $branch to origin..." >&2
git push --set-upstream origin "$branch"

if ! command -v gh >/dev/null 2>&1; then
  echo >&2
  echo "gh CLI not found — branch is pushed, open the PR manually:" >&2
  remote="$(git remote get-url origin)"
  case "$remote" in
    *github.com*)
      slug="$(printf '%s' "$remote" \
        | sed -E 's#\.git$##; s#^[a-z+]+://##; s#^[^/]*@##; s#:([^0-9])#/\1#; s#^[^/]+/##')"
      echo "  https://github.com/$slug/compare/$base...$branch?expand=1"
      ;;
    *)
      # Not GitHub (or a local path) — a compare URL would be a guess.
      echo "  origin: $remote" >&2
      echo "  open a pull request from '$branch' into '$base' on your hosting provider." >&2
      ;;
  esac
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo >&2
  echo "gh is installed but not authenticated — branch is pushed. Run 'gh auth login', then:" >&2
  echo "  gh pr create --base $base --head $branch --title \"$title\"" >&2
  exit 0
fi

set -- --base "$base" --head "$branch" --title "$title"
if [ -n "$body_file" ]; then
  set -- "$@" --body-file "$body_file"
else
  set -- "$@" --body "Implements spec \`$spec\`."
fi
if [ -n "$draft" ]; then
  set -- "$@" "$draft"
fi

gh pr create "$@"