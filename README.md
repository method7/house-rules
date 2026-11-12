# Method7 house rules

The rules every Method7 project shares, in one place, at a fixed version.

Each project used to keep its own copy of these rules, and the copies drifted
apart. This repository holds the rules that belong to Method7 as a whole, a
check that enforces the main one, and a skill that teaches an AI agent the
house style. Each project's own product rules stay in that project.

It follows the same pattern as `method7/discoverable`: a project uses one exact
commit, needs no password to get it, and only moves to a newer one through a
normal, reviewed pull request.

## What is in it

| File | What it is for |
| --- | --- |
| `RULES.md` | The general rules: UK English, dates, the em-dash ban and what replaces it, plain English, and the CI and security baseline. Short enough to read in two minutes. |
| `scripts/check-house-style.sh` | The check. Fails if any tracked file contains an em-dash (Unicode U+2014). Plain `sh` and `git grep`, so it needs no Node and works in PHP projects too. |
| `.github/workflows/house-style.yml` | A reusable GitHub Actions workflow that runs the check. A project calls it from its own CI with one line. |
| `skills/uk-house-style/SKILL.md` | A Claude Code skill: how to write and review copy in Method7 house style. |
| `scripts/sync-workflow.sh` | Copies the check script into the workflow. Only needed when changing the script. |
| `tests/check-house-style.test.sh` | Proves the check passes on clean files and fails on an em-dash. |

A few terms. **CI** (continuous integration) is the set of automatic checks
GitHub runs on every proposed change before it can be merged. A **reusable
workflow** is a set of those checks kept in one repository and called by
others. A **commit SHA** is the long code that names one exact version of a
repository, such as `3d3c42e5aac5ba805825da76410c181273ba90b1`.

## Adopting it in a project

Use one commit for everything, and always the full 40-character SHA. A branch
name such as `main` would change under you without a review.

```sh
sha=<the commit SHA you are adopting>
```

### 1. Call the check from CI

Add `.github/workflows/house-style.yml` to the project (or add the job to its
existing CI file):

```yaml
name: House style

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  house-style:
    uses: method7/house-rules/.github/workflows/house-style.yml@<commit SHA>
    # Optional: paths the check should skip, separated by spaces.
    with:
      exclude: ":!:legacy-v1"
```

The workflow holds no secrets and only reads the repository, so it is safe on
pull requests from anyone. Leave out `with:` to check every tracked file.

Excludes are for code the project does not own or will not change, such as an
archived old site or a vendored library. They are not a way round the rule
for new work.

### 2. Copy the rules and pull them into `CLAUDE.md`

```sh
mkdir -p .claude
gh api "repos/method7/house-rules/contents/RULES.md?ref=$sha" \
  -H 'Accept: application/vnd.github.raw' \
  | sed "s/<commit SHA>/$sha/" > .claude/house-rules.md
```

Then add this line near the top of the project's `CLAUDE.md`, so every agent
reads the rules before the project's own:

```markdown
@.claude/house-rules.md
```

The comment at the top of the copied file now records the commit it came
from.

### 3. Copy the skill

```sh
mkdir -p .claude/skills/uk-house-style
gh api "repos/method7/house-rules/contents/skills/uk-house-style/SKILL.md?ref=$sha" \
  -H 'Accept: application/vnd.github.raw' \
  > .claude/skills/uk-house-style/SKILL.md
```

The skill comes from the same commit as the rules, and the comment in
`.claude/house-rules.md` says so, so one line records the version of all three.

### 4. Run the check before opening the pull request

From anywhere in the project:

```sh
git grep -nIP '\x{2014}'
```

It should print nothing. To run exactly what CI runs, including any excludes:

```sh
gh api "repos/method7/house-rules/contents/scripts/check-house-style.sh?ref=$sha" \
  -H 'Accept: application/vnd.github.raw' \
  | sh -s -- ':!:legacy-v1'
```

Fix what it finds, or exclude it if it is not yours to change, then open one
pull request with all of the above.

### Why the files are copied, not linked

An agent reads its rules from the project, so they should sit in the project
and show up in its diffs, reviewed like any other change. The check is called
rather than copied, so a fix to it needs only a one-line change per project.

## Moving a project to a newer version

1. Pick the new commit SHA from this repository's `main`.
2. In the project, change the SHA in the `uses:` line.
3. Re-run the two copy commands in steps 2 and 3 with the new SHA.
4. Open a pull request. Its diff shows exactly which rules changed.

## Changing the rules or the check

Change them here, by pull request, never in a project's copy.

- Keep `RULES.md` general. A rule belongs here only if it is true of every
  Method7 project. Product rules, copy voice, lint settings and deploy steps
  stay in their own projects.
- If you change `scripts/check-house-style.sh`, run `sh scripts/sync-workflow.sh`
  and commit both files. CI fails if the workflow's copy and the script differ.
- Run `sh tests/check-house-style.test.sh` before pushing. It needs only `sh`
  and `git`.

This repository follows its own rules: its CI runs the check on itself, and
the tests create their em-dash at run time so the repository never contains
one.

## How the workflow gets the script

The workflow carries the script inside it, word for word, rather than
downloading it.

The alternative was a second checkout of this repository from inside the
workflow. The difficulty is knowing which commit to check out: a reusable
workflow cannot reliably tell which commit its caller pinned, so each project
would have to repeat the SHA in a second setting, and the two could drift
apart without anyone noticing. It would also fail for as long as this
repository is private.

Carried inside the workflow, the script is always the one from the commit the
project pinned, and nothing extra is fetched. The cost is keeping two copies
in step, which `scripts/sync-workflow.sh` does and CI enforces, so the
workflow still runs exactly the script a developer runs on a laptop.

## Licence

MIT. See `LICENSE`.
