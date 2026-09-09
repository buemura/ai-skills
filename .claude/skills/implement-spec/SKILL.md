---
name: implement-spec
description: Take a numbered spec file (specs/0001-title.md) from draft to open pull request — create a branch, implement the requirements, write tests, run the project's validation suite, commit, push, and open a PR against main. Use this whenever the user says "implement spec 0003", "build this spec", "let's implement the auth spec", "make the spec real", points at a spec file and asks for the code, or asks to pick up a Draft spec and ship it. Also use when the user wants an existing spec's implementation finished, validated, and put up for review.
---

# Implement Spec

Take a spec from `Draft` to an open pull request: branch, implement, test, validate, commit, push, PR.

Requires the `git` CLI, and `gh` for PR creation (there's a fallback if `gh` is missing).

## Before touching anything

Read the whole spec first. The Requirements section is the contract — everything in it must end up implemented or explicitly deferred with the user's agreement. Non-goals matter just as much: they tell you what not to build.

Then check the ground you're standing on:

```bash
git status --short          # working tree must be clean
git branch --show-current   # note where you are
git log --oneline -15       # learn the commit message style used here
```

If the tree is dirty, stop and ask. Uncommitted work belongs to the user, and sweeping it into a spec branch mixes their changes into a PR they didn't intend. Never stash or discard it on your own initiative.

If the spec has open questions that change what you'd build, ask them now rather than guessing and rewriting later. Open questions that don't block implementation can stay open.

## Create the branch

```bash
scripts/start_spec_branch.sh specs/0003-rate-limit-public-api.md
```

The script verifies the tree is clean, branches from an up-to-date `main` (fetching from `origin` when a remote exists), names the branch `spec/0003-rate-limit-public-api`, and prints it. Pass `--base <branch>` if the repo integrates somewhere other than `main`.

## Implement

Work through the Requirements in order. A few things that matter more here than in ordinary coding:

- **Follow the spec's Design section, and say so when you don't.** If the design turns out to be wrong or infeasible once you're in the code, that's normal and useful information — implement what actually works, then update the spec's Design section in the same branch so the document matches reality. A spec that quietly diverges from the code is worse than no spec.
- **Match the codebase, not your defaults.** Read neighboring files for structure, naming, error handling, and dependency conventions before adding new patterns.
- **Stay inside the spec's scope.** Refactors, drive-by fixes, and dependency bumps that the spec didn't ask for make the PR harder to review. Note them for the user instead of doing them.
- **Don't add dependencies casually.** If the spec didn't call for one, prefer what's already in the project; if a new one is genuinely needed, flag it in the PR body.

## Write tests

Every numbered requirement that describes observable behavior should have at least one test that would fail if that behavior regressed. Tests that only assert the code runs without throwing don't count.

Cover the boundaries the spec implies: the error cases, the empty and maximum inputs, the "what if the user does this twice" cases. Match the project's existing test framework, file layout, and naming — check how the neighboring tests are written before adding new ones.

If a requirement is genuinely hard to test (timing, external services, UI), say so explicitly rather than writing a test that pretends to cover it.

## Validate

Find the project's real commands rather than assuming. Check, in rough order of authority: the CI workflow files under `.github/workflows/`, then `Makefile`, `package.json` scripts, `pyproject.toml`, `Cargo.toml`, or `go.mod`. CI is the best source, because it's the same gate the PR will face.

Run the full set the project uses — typically tests, plus linting, formatting, and type checking where they exist. Run the whole suite, not just the new tests: the most common failure mode is code that satisfies the spec while breaking something adjacent.

**When something fails, fix the code.** Do not delete tests, add skip markers, loosen assertions, or widen lint ignores to get to green. If a pre-existing failure is unrelated to the spec, leave it alone and mention it to the user — don't fold someone else's broken test into this PR.

If a requirement can't be made to pass, stop and explain the conflict. A spec that's wrong needs a decision from the user, not a workaround.

## Update the spec status

Once the implementation is done and validation passes, flip the spec to `Implemented` in this same branch:

```bash
f=specs/0003-rate-limit-public-api.md
sed -i.bak -E "1,/^---$/{ s/^updated: .*/updated: $(date +%Y-%m-%d)/; s/^status: .*/status: Implemented/ }" "$f" && rm -f "$f.bak"
```

Including it in the PR means `main` gets the code and the accurate status in one merge, so the two can't drift apart. The range restriction keeps the substitution inside the frontmatter, so a body line beginning with `status:` survives untouched.

If the spec is only partly implemented, leave it as `Draft` and say why in the PR body.

## Commit

Match the commit style you saw in `git log`. If the project uses Conventional Commits, follow it; if it uses plain imperative subjects, do that instead. Reference the spec number either way, so the commit is traceable back to the document:

```
feat(api): add per-key rate limiting

Implements spec 0003-rate-limit-public-api.
```

Stage deliberately — `git add` the files you actually changed, and check `git status` for anything unexpected before committing. Never `git add -A` blindly: it's how build artifacts, local config, and credentials end up in history.

One commit is usually right for a single spec. Split into a few only when the change has genuinely separable parts a reviewer would want to read independently.

## Push and open the PR

```bash
scripts/open_spec_pr.sh specs/0003-rate-limit-public-api.md --body-file /tmp/pr-body.md
```

Write the body to a file first. A useful one covers what changed, how it was tested, and anything the reviewer should weigh in on:

```markdown
Implements spec [0003 — Rate limit the public API](specs/0003-rate-limit-public-api.md).

## What changed

Short prose, not a file listing — the diff already shows the files.

## Requirements

- [x] 1. Per-key request counting in a sliding window
- [x] 2. 429 with `Retry-After` when the limit is exceeded
- [ ] 3. Admin override — deferred, see below

## Testing

Which tests were added and what validation was run.

## Notes for review

Design divergences, deferred requirements, new dependencies, anything you had to
guess at.
```

The script pushes the branch with `-u origin`, then opens a PR against `main` with `gh`. If `gh` isn't installed or authenticated, it prints the compare URL for the user to open — the push still succeeded, so no work is lost. Pass `--base` if the target isn't `main`, and `--draft` for a draft PR.

Two hard limits on this step: never force-push, and never push to `main` directly. If the push is rejected because the branch diverged, stop and show the user the rejection rather than resolving it with force.

## Wrapping up

Report the branch name, the PR URL, which requirements are implemented and which aren't, the validation commands that ran and their results, and any place the implementation diverged from the spec's design. If validation didn't fully pass, lead with that — it's the thing the user most needs to know.
