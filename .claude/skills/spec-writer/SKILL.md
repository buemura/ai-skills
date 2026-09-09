---
name: spec-writer
description: Turn a message, prompt, or feature idea into a numbered spec document (0001-title.md) with status, created/updated dates, and the author pulled from git config. Use this whenever the user says "write a spec", "spec this out", "turn this into a spec", "create a spec for X", "add a spec", asks to update or mark a spec as implemented, or describes a feature/change and asks for it to be written up as a formal document — even if they don't use the word "spec" but clearly want a durable, numbered design or requirements doc in the repo.
---

# Spec Writer

Turn a rough message, prompt, or feature description into a numbered spec file that lives in the repository alongside the code.

## What a spec looks like

Filename: `NNNN-kebab-case-title.md`, where `NNNN` is a zero-padded sequential number starting at `0001`. Examples: `0001-user-authentication.md`, `0002-rate-limit-public-api.md`.

Every spec opens with YAML frontmatter, then the body:

```markdown
---
number: "0001"
title: User authentication
status: Draft
author: Jane Doe
created: 2026-09-08
updated: 2026-09-08
---

# 0001 — User authentication

## Summary

One paragraph: what this is and why it exists.

## Motivation

The problem being solved, and what happens if it isn't.

## Goals

- Bulleted, concrete, checkable.

## Non-goals

- Explicitly out of scope, so the boundary is clear later.

## Requirements

Numbered so they can be referenced in review and in commits.

1. ...
2. ...

## Design

How it works. Data model, interfaces, flow, file layout — whatever the change actually needs. Skip subsections that don't apply rather than padding them.
```

`status` is `Draft` or `Implemented` — nothing else, so the values stay greppable.

There is no "Open questions" section, and that's deliberate: a finished spec has none. See "Resolve the gaps before writing" below.

## Where specs go

1. Default to `docs/specs/`, creating it if it doesn't exist.
2. If the repo already keeps specs somewhere else — a root-level `specs/`, `.specs/`, `rfcs/` — use that instead. Matching the convention already in the repo matters more than any default, and scattering specs across two directories is worse than either choice alone.

If existing specs use a different layout (a `NNNN-title/` directory per spec, a different frontmatter shape, an extra section every spec has), read one of them first and match it. A spec that looks unlike its neighbors is worse than a slightly non-standard one.

## Creating a spec

Do this _after_ resolving any open questions with the user (see below) — a spec file that sits half-written on disk while the user is still deciding is easy to forget and easy to commit by accident.

Compute the number, author, and date with the shell rather than by memory — the number depends on what's already on disk, and the author has to come from git config. Run this first:

```bash
SPEC_DIR=docs/specs   # or whatever the repo already uses
mkdir -p "$SPEC_DIR"

last=$(ls -1 "$SPEC_DIR" 2>/dev/null | sed -nE 's/^([0-9]{4}).*/\1/p' | sort -n | tail -1)
# Strip leading zeros before the increment, or 0008 is read as octal and fails.
next=$(( $(printf '%s' "${last:-0}" | sed 's/^0*//; s/^$/0/') + 1 ))
num=$(printf '%04d' "$next")

author=$(git config user.name || git config user.email || echo "${USER:-unknown}")
today=$(date +%Y-%m-%d)

echo "number=$num author=$author date=$today"
```

Then slugify the title (lowercase, non-alphanumerics to single hyphens, no leading or trailing hyphen) and write `$SPEC_DIR/$num-$slug.md` with the frontmatter above filled in from those values. Check the path doesn't already exist before writing.

## Turning the message into the spec

The user's message is source material, not the spec. Do not paste it in as the summary.

- Expand terse phrasing into concrete requirements. "Should be fast" becomes a stated latency target.
- Keep specifics verbatim where the user was precise — exact field names, numbers, error codes, and formats they gave are decisions, not suggestions.
- Don't invent scope. A spec that quietly adds three features the user never mentioned is harder to review than one that's honestly thin.

## Resolve the gaps before writing

A finished spec contains no open questions. Anything you'd otherwise park under an "Open questions" heading is a decision the user needs to make, so ask them for it instead of deferring — an unanswered question in a merged spec tends to stay unanswered until it surfaces as a bug.

So: draft the spec in your head first, collect everything you'd have to guess at, and ask before creating the file.

**Ask once, not one at a time.** Work out the complete list, then put it in a single message. Drip-feeding questions turns a two-minute exchange into a twenty-message interview, and the user can't see where it ends.

**Give each question a recommended answer.** The user should be able to reply "all your defaults are fine" and be done. A question with no suggested answer pushes the whole design burden back onto them, which is what they asked you to do in the first place.

```
Before I write this up, four things I need from you:

1. Rate limit scope — per API key, or per IP? (I'd suggest per key; IP breaks
   for customers behind shared NAT.)
2. Limit value — I'd suggest 1000 req/min, but that's a guess without traffic data.
3. What happens at the limit — 429 with Retry-After, or silent queueing?
   (Suggest 429; queueing hides the problem from clients.)
4. Do admin tokens bypass the limit entirely, or get a higher ceiling?
```

**Only ask what changes the document.** Questions with real consequences for the requirements or design belong here. Choices that can be made freely at implementation time — variable naming, which helper file something lives in, the sort order of an internal list — don't, and asking about them buries the questions that matter.

**If the user declines to decide**, or answers only some, take your recommended answer for the rest, write it into the spec as a settled decision, and tell them plainly which ones you chose. "You decide" is a valid answer; it isn't a reason to leave a hole in the document.

Match the level of detail to what you were given. A one-line prompt needs more questions before it can become a spec; a detailed message may need none at all — in which case don't manufacture any, just write it.

## Updating a spec

Any edit to a spec bumps `updated`. Restrict the substitution to the frontmatter block so a stray line in the body can't be clobbered:

```bash
f=docs/specs/0001-user-authentication.md
sed -i.bak -E "1,/^---$/{ s/^updated: .*/updated: $(date +%Y-%m-%d)/ }" "$f" && rm -f "$f.bak"
```

To also change the status, add the second expression:

```bash
sed -i.bak -E "1,/^---$/{ s/^updated: .*/updated: $(date +%Y-%m-%d)/; s/^status: .*/status: Implemented/ }" "$f" && rm -f "$f.bak"
```

`created` never changes. Mark a spec `Implemented` when the described behavior actually exists in the code — not when the work starts. If the implementation drifted from the spec, update the spec body to match reality in the same pass, otherwise `Implemented` becomes a lie people stop trusting.

Never renumber an existing spec. Numbers are permanent identifiers; superseded specs stay in place, and a newer spec references the one it replaces.

## Wrapping up

Report the created or modified path, the assigned number, and the status.

If you settled any question on the user's behalf — because they said "you decide", or didn't answer that one — list those decisions in the chat. They're the parts of the spec most likely to be wrong, and they're easy to miss inside a finished document that reads as though everything was settled.
