#!/usr/bin/env bash
# Bump a spec's `updated` date, and optionally change its status.
#
#   touch_spec.sh docs/specs/0001-user-authentication.md
#   touch_spec.sh docs/specs/0001-user-authentication.md --status Implemented

set -euo pipefail

file=""
status=""

usage() {
  cat <<'USAGE'
Usage: touch_spec.sh <spec-file> [--status Draft|Implemented]

Sets `updated` to today. With --status, also changes the status field.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--status) status="${2:?--status needs a value}"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)           file="$1"; shift ;;
  esac
done

if [ -z "$file" ]; then
  echo "Error: a spec file is required." >&2
  usage >&2
  exit 2
fi

if [ ! -f "$file" ]; then
  echo "Error: no such file: $file" >&2
  exit 1
fi

case "$status" in
  ""|Draft|Implemented) ;;
  *) echo "Error: status must be Draft or Implemented (got: $status)" >&2; exit 2 ;;
esac

today="$(date +%Y-%m-%d)"
tmp="$(mktemp)"

awk -v today="$today" -v newstatus="$status" '
  NR == 1 && $0 == "---" { infm = 1; print; next }
  infm && $0 == "---"    { infm = 0; print; next }
  infm && /^updated:/     { print "updated: " today; found_updated = 1; next }
  infm && /^status:/ && newstatus != "" { print "status: " newstatus; next }
  { print }
  END { if (!found_updated) exit 3 }
' "$file" > "$tmp" || {
  rc=$?
  rm -f "$tmp"
  if [ "$rc" -eq 3 ]; then
    echo "Error: no 'updated:' field found in the frontmatter of $file" >&2
  fi
  exit "$rc"
}

cat "$tmp" > "$file"
rm -f "$tmp"

if [ -n "$status" ]; then
  echo "$file: updated=$today, status=$status"
else
  echo "$file: updated=$today"
fi