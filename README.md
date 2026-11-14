# Method7 house rules

The rules every Method7 project shares, in one place, at a fixed version.

Each project used to keep its own copy of these rules and the copies drifted
apart. This repository holds the rules that belong to Method7 as a whole, a
check that enforces the main one and a skill that teaches an AI agent the
house style. Each project's own product rules stay in that project.

It follows the same pattern as `method7/discoverable`: a project uses one exact
commit, needs no password to get it and only moves to a newer one through a
normal, reviewed pull request.

## What is in it

| File | What it is for |
| --- | --- |
| `RULES.md` | The general rules: UK English, dates, the em-dash and comma-before-"and" bans and what replaces them, plain English, the CI and security baseline and the safety rules for AI agents. Short enough to read in two minutes. |
| `settings/claude-baseline.json` | The agent safety rules as Claude Code permission settings, so Claude Code enforces them rather than leaving them to the agent. A project copies it to `.claude/settings.json`. Each rule is explained [below](#the-permission-baseline). |
| `scripts/check-house-style.sh` | The check. Fails if any tracked file contains an em-dash (Unicode U+2014), a comma before "and" or a sentence starting with "And". Plain `sh` and `git grep`, so it needs no Node and works in PHP projects too. |
| `.github/workflows/house-style.yml` | A reusable GitHub Actions workflow that runs the check. A project calls it from its own CI with one line. |
| `skills/uk-house-style/SKILL.md` | A Claude Code skill: how to write and review copy in Method7 house style. |
| `skills/humanise-copy/SKILL.md` | A Claude Code skill: how to edit the habits of AI writing out of copy, such as stock phrases, filler and everything in threes, without changing what it says. |
| `scripts/sync-workflow.sh` | Copies the check script into the workflow. Only needed when changing the script. |
| `tests/check-house-style.test.sh` | Proves the check passes on clean files and fails on each thing it bans. |

A few terms. **CI** (continuous integration) is the set of automatic checks
GitHub runs on every proposed change before it can be merged. A **reusable
workflow** is a set of those checks kept in one repository and called by
others. A **commit SHA** is the long code that names one exact version of a
repository, such as `3d3c42e5aac5ba805825da76410c181273ba90b1`.

## Adopting it in a project

Use one commit for everything and always the full 40-character SHA. A branch
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
archived old site, a vendored library or a `LICENSE` file, whose legal
wording must stay exactly as written. They are not a way round the rule
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

### 3. Copy the skills

```sh
for skill in uk-house-style humanise-copy; do
  mkdir -p ".claude/skills/$skill"
  gh api "repos/method7/house-rules/contents/skills/$skill/SKILL.md?ref=$sha" \
    -H 'Accept: application/vnd.github.raw' \
    > ".claude/skills/$skill/SKILL.md"
done
```

### 4. Copy the permission baseline

```sh
gh api "repos/method7/house-rules/contents/settings/claude-baseline.json?ref=$sha" \
  -H 'Accept: application/vnd.github.raw' \
  > .claude/settings.json
```

If the project already has a `.claude/settings.json`, merge the two by hand
instead, keeping every `deny` and `ask` rule from the baseline. Check that
`.gitignore` lists `.claude/settings.local.json`, so each person's own
settings stay out of the repository (rule 9).

The skills and the baseline come from the same commit as the rules and the
comment in `.claude/house-rules.md` says so, so one line records the version
of everything.

### 5. Run the check before opening the pull request

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
3. Re-run the copy commands in steps 2–4 with the new SHA.
4. Open a pull request. Its diff shows exactly which rules changed.

## The permission baseline

`settings/claude-baseline.json` turns the agent rules in `RULES.md` (rules
10–14) into Claude Code permission settings. Claude Code checks every action
against them before the agent can take it, so the agent cannot talk itself
past them. JSON has no comments, so this section explains each rule.

The syntax follows Claude Code's own documentation, "Configure permissions"
at https://code.claude.com/docs/en/permissions, checked on 12 November 2026
against Claude Code 2.1.311. (The older `docs.claude.com/en/docs/claude-code/`
pages now redirect to `code.claude.com`.) The points that matter here:

- **`deny`** blocks an action outright. **`ask`** stops and asks a person
  first. Claude Code checks `deny`, then `ask`, then `allow`. A broader
  `deny` always beats a narrower `allow`, in any settings file. So a
  project or a person can add rules on top of the baseline, but cannot
  switch one of its rules off.
- **`Bash(...)`** matches the command as written. `*` stands for any text,
  spaces included. Commands joined with `&&`, `;` or `|` are checked one by
  one and a few wrappers such as `timeout` and `nohup` are looked through.
- **`Read(...)`** uses the same patterns as a `.gitignore` file. `~/` starts
  at the home folder and `//` at the root of the disk. `*` stays within one
  folder and `**` reaches into every folder below. A `Read` deny also stops
  the agent editing that path and stops common file commands in Bash such
  as `cat` and `head`.
- **`mcp__*__*send*`** is a pattern over tool names: any tool from any
  connected service (an MCP server) whose name contains `send`.

### Rule 10: pushing

| Rule | Why |
| --- | --- |
| `Bash(git push * main)`, `Bash(git push * main *)` | Push to `main` by name, with or without options after it. |
| `Bash(git push *:main)`, `Bash(git push *:main *)` | Push something else onto `main`, such as `HEAD:main`. |
| `Bash(git push */main)` | Push to `main` by its full name, `refs/heads/main`. |
| The same five for `master` | Older repositories call their main branch `master`. |
| `Bash(git push --force*)`, `Bash(git push * --force*)` | Force-push, including `--force-with-lease`, wherever the option goes. |
| `Bash(git push -f*)`, `Bash(git push * -f*)` | The short form, `-f`. |
| `Bash(git push *+*)` | A `+` before a branch name is a force-push too. It also blocks pushing a branch whose name contains `+`, which is rare. |

Pushing any other branch is not blocked, because pushing its own branch is
how an agent opens a pull request.

### Rule 11: private keys and secrets

| Rule | Why |
| --- | --- |
| `Read(~/.ssh/**)` | SSH keys, which open servers and GitHub. |
| `Read(~/.aws/**)` | Amazon Web Services keys. |
| `Read(~/.gnupg/**)` | GPG keys, used to sign and decrypt. |
| `Read(~/Library/Keychains/**)`, `Read(//Library/Keychains/**)` | The macOS keychain files, for one person and for the whole machine. |
| `Bash(security *)` | The macOS command that reads passwords out of the keychain. |
| `Read(//**/.env)` | A `.env` file anywhere on the disk. These hold a project's passwords and keys. |
| `Read(.env.*)`, then `Read(!.env.example)` | Variants such as `.env.local` and `.env.production`, in the project and every folder below it, except `.env.example`, which holds no real values. The `!` exception only works on rules written without `~/` or `//`, which is why this pair is scoped to the project. |

### Rule 12: no `sudo`

| Rule | Why |
| --- | --- |
| `Bash(sudo *)` | `sudo` runs a command with full control of the machine. |

### Rule 13: no merging, deploying or FTP

| Rule | Why |
| --- | --- |
| `Bash(gh pr merge *)` | Merging a pull request from the command line. Merges deploy, so only Simon merges. |
| `Bash(gh api *merge*)` | Merging through GitHub's API instead. |
| `Bash(gh workflow run *)` | Starting a GitHub Actions workflow by hand, which is how a deploy could be run without a merge. |
| `Bash(ftp *)`, `Bash(sftp *)`, `Bash(lftp *)`, `Bash(curl *ftp://*)` | Copying files straight to a server, round the reviewed route. |

### Rule 14: ask before acting outward

These are `ask` rules: the agent may still do them, once a person says yes.
In a run where nobody can answer, such as `claude -p`, they are refused.

| Rule | Why |
| --- | --- |
| `Bash(gh issue comment *)`, `Bash(gh pr comment *)`, `Bash(gh pr review *)` | Posting on GitHub in Simon's name. |
| `Bash(gh release create *)` | Publishing a release. |
| `Bash(gh api *-X *)`, `Bash(gh api *--method *)`, `Bash(gh api *-f *)`, `Bash(gh api *-F *)`, `Bash(gh api *--field *)`, `Bash(gh api *--raw-field *)` | Any GitHub API call that changes something. Calls that only read are left alone. |
| `Bash(curl *-X *)`, `Bash(curl *--request *)`, `Bash(curl *-d *)`, `Bash(curl *--data*)`, `Bash(curl *-F *)`, `Bash(curl *--form *)` | Sending data to a website, such as a form, a payment or a change to live data. |
| `Bash(mail *)`, `Bash(sendmail *)` | Sending email from the command line. |
| `Bash(osascript *)` | Scripts that drive Mac apps, which can send email or messages. |
| `mcp__*__*send*`, `mcp__*__*post*`, `mcp__*__*publish*`, `mcp__*__*reply*` | Tools from connected services, such as an email or chat connector, that send, post, publish or reply. |

Rule 15, on instructions found in content, cannot be written as a setting.
It stays a written rule.

### What the baseline does not stop

Deny rules match the command as it is written, so they are guardrails, not a
vault. The documentation says so and tests in Roofus (decision 0012)
confirmed it: every rule held for the command as normally written and each
gave way to the same thing written another way. These got through in
testing, against a fake remote and decoy files:

- `git -C . push origin HEAD:main`, with an option before `push`
- `git push origin HEAD` while on `main`, which never names the branch
- a command wrapped in `sh -c '...'` or `bash -c '...'`, for `sudo` and
  `gh pr merge` alike
- a short Python script that opens a key file itself
- `grep -r` over a folder, which reads a `.env` file without naming it
- `curl --json`, which sends data without `-d` or `-X`
- a short Python script that edits `.claude/settings.json` itself, which
  could remove the rules (writing to it with `>>` was stopped for approval).
  The baseline now denies editing any Claude settings file (an `Edit` rule
  covers every file-editing tool, Write included), which closes the easy
  route. A project's CI should also fail if its
  `.claude/settings.json` differs from this baseline, so a changed copy can
  never reach `main`; Roofus does this

That is why branch protection on GitHub stays the final lock: it refuses a
push to `main` however the command was written. The baseline stops the
mistakes an agent is likely to make and makes a deliberate workaround stand
out in the transcript. The settings file is tracked by git, so a change to
it shows in the pull request's diff. Adding a pattern for every spelling
would never end. For a stronger wall around files and the network, Claude
Code has a sandbox mode, which this baseline does not turn on.

## Changing the rules or the check

Change them here, by pull request, never in a project's copy.

- Keep `RULES.md` general. A rule belongs here only if it is true of every
  Method7 project. Product rules, copy voice, lint settings and deploy steps
  stay in their own projects.
- If you change `scripts/check-house-style.sh`, run `sh scripts/sync-workflow.sh`
  and commit both files. CI fails if the workflow's copy and the script differ.
- Run `sh tests/check-house-style.test.sh` before pushing. It needs only `sh`
  and `git`.

This repository follows its own rules: its CI runs the check on itself and
the tests create their em-dash at run time so the repository never contains
one.

## How the workflow gets the script

The workflow carries the script inside it, word for word, rather than
downloading it.

The alternative was a second checkout of this repository from inside the
workflow. The difficulty is knowing which commit to check out: a reusable
workflow cannot reliably tell which commit its caller pinned, so each project
would have to repeat the SHA in a second setting and the two could drift
apart without anyone noticing. It would also fail for as long as this
repository is private.

Carried inside the workflow, the script is always the one from the commit the
project pinned and nothing extra is fetched. The cost is keeping two copies
in step, which `scripts/sync-workflow.sh` does and CI enforces, so the
workflow still runs exactly the script a developer runs on a laptop.

## Licence

MIT. See `LICENSE`.
