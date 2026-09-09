---
name: spec-to-issue
description: Open a GitHub issue from a numbered spec file (docs/specs/0003-title.md), with the spec's summary, a checklist of its requirements, and a link back to the document. Use this whenever the user says "create an issue for spec 0003", "file a GitHub issue from this spec", "put this spec on the board", "open a ticket for that spec", or asks to track, assign, or hand off a spec as work. Also use when a spec has just been written and the user wants it queued up for someone to pick up.
---

# Spec to Issue

Turn a spec into a trackable GitHub issue: title, summary, requirements checklist, and a link back to the spec.

Requires the `gh` CLI, authenticated (`gh auth status`), in a repo with a GitHub remote.

## Read the spec first

Open the spec and check three things before doing anything:

- **Status.** If it's already `Implemented`, the work is done — ask the user what they're after before filing an issue for it. They may be looking at the wrong spec number.
- **An issue may already exist.** The script searches open and closed issues for the spec number and refuses to create a duplicate, but a differently-worded title can slip past it. If you spot a match it missed, show the user and let them decide.
- **Requirements.** These become the issue's checklist, so they're the part worth reading closely.

## Write the issue body

Let the script generate the default body when the spec is straightforward. Write your own when the spec needs framing the document doesn't provide — a dependency on other work, an explanation of why now, a scope note for whoever picks it up.

A good body is short, because the spec is the real document and duplicating it into the issue guarantees the two drift apart:

```markdown
Implements [0003 — Rate limit the public API](docs/specs/0003-rate-limit-public-api.md).

Public endpoints currently have no request ceiling, so a single misbehaving
client can degrade the API for everyone.

## Requirements

- [ ] 1. Per-key request counting in a sliding window
- [ ] 2. 429 with `Retry-After` when the limit is exceeded
- [ ] 3. Admin tokens get a raised ceiling, not a bypass

Full detail, including the non-goals, is in the spec.
```

Link to the spec by repository-relative path so GitHub resolves it against the default branch. If the spec isn't merged to the default branch yet, say so in the body — otherwise the link 404s and the reader assumes the issue is stale.

## Create it

```bash
scripts/create_spec_issue.sh docs/specs/0003-rate-limit-public-api.md
```

Options:

- `--body-file <path>` — use your own body instead of the generated one
- `--label <name>` — repeatable; labels that don't exist in the repo are skipped with a warning rather than failing the call
- `--assignee <user>` — repeatable; `@me` works
- `--milestone <name>`
- `--dry-run` — print the title, labels, and body without creating anything
- `--force` — create even though the duplicate search found something
- `--repo <owner/name>` — target a different repo

If the script exits reporting a possible duplicate, don't reach for `--force` reflexively. Show the user what it found. Re-filing work that already has an issue splits the discussion across two threads, and the older issue usually has context the new one won't.

**Use `--dry-run` first when you generated the body yourself, or when the spec's requirements are long enough that the checklist might have parsed badly.** An issue is visible to everyone watching the repo the moment it's created, and editing a mistake leaves the original in the notification emails. A dry run costs nothing.

If the user hasn't said which labels or assignees they want, ask before creating rather than guessing — those choices route the work to people, and a wrong assignee is a notification someone has to untangle.

## After creating

Report the issue URL and number.

Consider mentioning the issue number in the spec, or the spec path in later commits, so the two stay findable from each other. Don't edit the spec's frontmatter to add an issue field unless the user asks — the spec format is defined elsewhere, and quietly adding fields to it makes specs inconsistent across the repo.

## What not to do

Don't create an issue per requirement. The spec is the unit of work; a checklist inside one issue keeps the discussion in one place, and seven issues that all link back to the same document is noise on the board. If the user genuinely wants the requirements split across issues, do it — but say once that the spec-sized issue is usually easier to track.

Don't close or edit existing issues as part of this. Creating is the whole job.
