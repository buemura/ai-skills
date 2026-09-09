#!/usr/bin/env bash
# Create a new numbered spec file.
#
#   new_spec.sh "User authentication"
#   new_spec.sh -d specs "Rate limit the public API"   # override the default
#
# Prints the path of the created file.

set -euo pipefail

spec_dir="${SPEC_DIR:-docs/specs}"
author=""
title=""

usage() {
  cat <<'USAGE'
Usage: new_spec.sh [options] "Spec title"

Options:
  -d, --dir <path>      Spec directory (default: docs/specs, or $SPEC_DIR)
  -a, --author <name>   Override author (default: git config user.name)
  -h, --help            Show this help
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dir)    spec_dir="${2:?--dir needs a value}"; shift 2 ;;
    -a|--author) author="${2:?--author needs a value}"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    --)          shift; title="${1:-}"; break ;;
    -*)          echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)           title="$1"; shift ;;
  esac
done

if [ -z "$title" ]; then
  echo "Error: a spec title is required." >&2
  usage >&2
  exit 2
fi

# Author: git name, then git email, then $USER.
if [ -z "$author" ]; then
  author="$(git config user.name 2>/dev/null || true)"
fi
if [ -z "$author" ]; then
  author="$(git config user.email 2>/dev/null || true)"
fi
if [ -z "$author" ]; then
  author="${USER:-unknown}"
fi

slug="$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"

if [ -z "$slug" ]; then
  echo "Error: title produced an empty slug." >&2
  exit 2
fi

mkdir -p "$spec_dir"

# Highest existing NNNN prefix in the directory, +1.
last="$(ls -1 "$spec_dir" 2>/dev/null | sed -nE 's/^([0-9]{4}).*/\1/p' | sort -n | tail -1 || true)"
if [ -z "$last" ]; then
  next=1
else
  next=$((10#$last + 1))
fi
num="$(printf '%04d' "$next")"

today="$(date +%Y-%m-%d)"
path="$spec_dir/$num-$slug.md"

if [ -e "$path" ]; then
  echo "Error: $path already exists." >&2
  exit 1
fi

cat > "$path" <<EOF
---
number: "$num"
title: $title
status: Draft
author: $author
created: $today
updated: $today
---

# $num — $title

## Summary

## Motivation

## Goals

## Non-goals

## Requirements

## Design
EOF

echo "$path"