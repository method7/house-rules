<!--
Copied from method7/house-rules at commit <commit SHA>, as was
.claude/skills/uk-house-style/SKILL.md, and the house-style workflow is called
at the same commit. Do not edit these copies: change method7/house-rules, then
re-copy both files and move the workflow to the new commit.
-->

# Method7 house rules

These rules apply to every Method7 project. A project's own `CLAUDE.md` adds
the rules for that product; where the two disagree, stop and say so rather
than picking one.

## Writing

1. **No em-dashes, anywhere.** Never use the em-dash, Unicode U+2014. The ban
   covers everything: copy, documentation, code comments and commit messages.
   Instead use:
   - a spaced en-dash ` – ` (U+2013) for an aside
   - otherwise a comma, colon or full stop
   - an unspaced en-dash for a range: `2025–2026`, `Mon–Fri`, `£5–10`

2. **UK English.** `-ise` not `-ize` (organise, recognise), `colour`,
   `behaviour`, `centre`. `licence` is the noun, `license` the verb. Code may
   still use US spellings where a language or library needs them (`color` in
   CSS, `initialize` in an API).

3. **Dates.** In prose, write `12 November 2026`, never `November 12, 2026` or
   `12/11/2026`. Where a machine reads the date (frontmatter, file names), use
   ISO: `2026-11-12`.

4. **Plain English.** Write for business owners, not engineers. Prefer the
   short word, say who did what, and explain a technical term the first time
   it appears, or leave it out.

## Checking

5. **Check before committing.** Run the em-dash check over tracked files:

   ```sh
   git grep -nIP '\x{2014}'
   ```

   It should print nothing. Use `git grep`, not `grep`: macOS `grep` has no
   `-P`, and a command that fails to run prints nothing, which looks exactly
   like a pass. CI runs the same check through the shared `house-style`
   workflow and fails the build if it finds one.

## CI and security

6. **Pull-request CI holds no credentials.** A workflow that runs on a pull
   request must not be given secrets, deploy keys or tokens beyond the
   automatic read-only one, so a hostile pull request can reach nothing.
   Deploy credentials live on a GitHub environment that pull-request workflows
   cannot read.

7. **Read-only token.** Every workflow sets `permissions: contents: read` at
   the top, and grants more to a single job only when that job needs it.

8. **Cancel stale checks, never a deploy.** CI cancels a run that a newer
   push has replaced. A deploy is queued, never cancelled part way through.

9. **No secrets in the repository.** No keys, passwords or tokens in source
   control, ever. `.env` files and Claude Code's local settings
   (`.claude/settings.local.json`) are ignored by git.
