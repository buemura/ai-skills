#!/usr/bin/env bash
# Create a GitHub issue from a numbered spec file.
#
#   create_spec_issue.sh docs/specs/0003-rate-limit-public-api.md
#   create_spec_issue.sh docs/specs/0003-rate-limit-public-api.md --dry-run
#   create_spec_issue.sh docs/specs/0003-rate-limit-public-api.md --label spec --assignee @me

set -euo pipefail

spec=""
body_file=""
repo=""
milestone=""
dry_run=""
force=""
labels=()
assignees=()

usage() {
  cat <<'USAGE'
Usage: create_spec_issue.sh <spec-file> [options]

Options:
  -f, --body-file <path>   Use this body instead of the generated one
  -l, --label <name>       Add a label (repeatable; missing labels are skipped)
  -a, --assignee <user>    Assign a user (repeatable; @me works)
  -m, --milestone <name>   Set the milestone
  -r, --repo <owner/name>  Target a different repository
  -n, --dry-run            Print the issue without creating it
      --force              Create even if a possible duplicate issue exists
  -h, --help               Show this help
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--body-file) body_file="${2:?--body-file needs a value}"; shift 2 ;;
    -l|--label)     labels+=("${2:?--label needs a value}"); shift 2 ;;
    -a|--assignee)  assignees+=("${2:?--assignee needs a value}"); shift 2 ;;
    -m|--milestone) milestone="${2:?--milestone needs a value}"; shift 2 ;;
    -r|--repo)      repo="${2:?--repo needs a value}"; shift 2 ;;
    -n|--dry-run)   dry_run=1; shift ;;
    --force)        force=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    -*)             echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)              spec="$1"; shift ;;
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

stem="$(basename "$spec" .md)"
case "$stem" in
  [0-9][0-9][0-9][0-9]-*) ;;
  *) echo "Error: spec filename must look like NNNN-title.md (got: $stem)" >&2; exit 2 ;;
esac

num="${stem%%-*}"

# --- read the spec -----------------------------------------------------------

frontmatter_field() {
  sed -nE "1,/^---$/{ s/^$1:[[:space:]]*//p; }" "$spec" | head -1 | sed -E 's/^"(.*)"$/\1/'
}

title_text="$(frontmatter_field title)"
[ -n "$title_text" ] || title_text="$(printf '%s' "$stem" | cut -d- -f2- | tr '-' ' ')"
status="$(frontmatter_field status)"

issue_title="$num — $title_text"

if [ "$status" = "Implemented" ]; then
  echo "Warning: $spec is already marked Implemented. Filing an issue for finished work is usually a mistake." >&2
fi

section() {
  awk -v want="$1" '
    /^## / { h = substr($0, 4); sub(/[[:space:]]+$/, "", h); in_s = (h == want); next }
    in_s   { print }
  ' "$spec"
}

# Requirements become checklist items. Numbered items are the documented form;
# bullets are accepted too, since specs in the wild use both. Continuation lines
# fold into the item above so a wrapped requirement stays on one line.
requirements_checklist() {
  section "Requirements" | awk '
    function flush() { if (item != "") { print "- [ ] " item; item = "" } }
    /^[0-9]+\./                { flush(); item = $0; next }
    /^[-*][[:space:]]+/        { flush(); item = $0; sub(/^[-*][[:space:]]+/, "", item); next }
    /^[[:space:]]*$/           { flush(); next }
    item != ""                 { sub(/^[[:space:]]+/, ""); item = item " " $0; next }
    { next }
  '
}

summary_text() {
  section "Summary" | sed -E '/^[[:space:]]*$/d'
}

# --- duplicate check ---------------------------------------------------------

gh_args=()
[ -n "$repo" ] && gh_args+=(--repo "$repo")

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  existing="$(gh issue list ${gh_args[@]+"${gh_args[@]}"} --state all --search "$num in:title" \
                --json number,title,url,state \
                --template '{{range .}}#{{.number}} [{{.state}}] {{.title}} — {{.url}}{{"\n"}}{{end}}' 2>/dev/null || true)"
  if [ -n "$existing" ]; then
    echo "Possible existing issues for spec $num:" >&2
    printf '%s\n' "$existing" >&2
    if [ -z "$dry_run" ] && [ -z "$force" ]; then
      echo "Refusing to create a possible duplicate. Review the above, then re-run with --force if it's genuinely a new issue." >&2
      exit 3
    fi
  fi
fi

# --- body --------------------------------------------------------------------

tmp_body=""
if [ -n "$body_file" ]; then
  if [ ! -f "$body_file" ]; then
    echo "Error: no such body file: $body_file" >&2
    exit 1
  fi
else
  tmp_body="$(mktemp)"
  trap 'rm -f "$tmp_body"' EXIT
  {
    printf 'Implements [%s](%s).\n' "$issue_title" "$spec"
    summary="$(summary_text)"
    if [ -n "$summary" ]; then
      printf '\n%s\n' "$summary"
    fi
    reqs="$(requirements_checklist)"
    if [ -n "$reqs" ]; then
      printf '\n## Requirements\n%s\n' "$reqs"
    fi
    printf '\nFull detail is in the spec.\n'
  } > "$tmp_body"
  body_file="$tmp_body"
fi

# --- dry run -----------------------------------------------------------------

if [ -n "$dry_run" ]; then
  echo "--- title ---"
  echo "$issue_title"
  echo "--- labels ---"
  if [ ${#labels[@]} -gt 0 ]; then printf "%s\n" "${labels[@]}"; else echo "(none)"; fi
  echo "--- assignees ---"
  if [ ${#assignees[@]} -gt 0 ]; then printf '%s\n' "${assignees[@]}"; else echo "(none)"; fi
  echo "--- body ---"
  cat "$body_file"
  exit 0
fi

# --- create ------------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI not found. Install it, or create the issue manually — run with --dry-run to get the body." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

# Drop labels that don't exist rather than failing the whole call.
create_args=(--title "$issue_title" --body-file "$body_file")
[ -n "$repo" ] && create_args+=(--repo "$repo")
[ -n "$milestone" ] && create_args+=(--milestone "$milestone")

if [ ${#labels[@]} -gt 0 ]; then
  known="$(gh label list ${gh_args[@]+"${gh_args[@]}"} --limit 200 --json name \
             --template '{{range .}}{{.name}}{{"\n"}}{{end}}' 2>/dev/null || true)"
  for l in "${labels[@]}"; do
    if [ -z "$known" ] || printf '%s\n' "$known" | grep -qxF "$l"; then
      create_args+=(--label "$l")
    else
      echo "Warning: label '$l' does not exist in this repo — skipping it." >&2
    fi
  done
fi

for a in ${assignees[@]+"${assignees[@]}"}; do
  create_args+=(--assignee "$a")
done

gh issue create "${create_args[@]}"