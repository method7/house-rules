#!/bin/sh
# check-house-style.sh: fail if any tracked file contains an em-dash (U+2014).
#
# Usage, from anywhere inside a git work tree:
#
#   sh check-house-style.sh [exclude-pathspec ...]
#   sh check-house-style.sh ':!:legacy-v1' ':!:vendor'
#
# Only exclude pathspecs are accepted (':!:path', ':^path' or
# ':(exclude)path'). Anything else would quietly narrow the check, so it is
# refused.
#
# Why git grep and not grep: macOS grep has no -P, and a grep that fails to
# run prints nothing, which looks exactly like a pass. git grep behaves the
# same on every machine and only reads tracked files.
#
# Exit codes: 0 clean, 1 em-dashes found, 2 the check could not run.
# Anything other than 0 must fail the build.
#
# This file is also copied, byte for byte, into
# .github/workflows/house-style.yml. Edit it here, then run
# scripts/sync-workflow.sh. The repository's own CI fails if the copies differ.

set -u

me=check-house-style

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "$me: not inside a git work tree, so nothing was checked." >&2
  exit 2
}
cd "$root" || exit 2

for spec in "$@"; do
  case $spec in
    ':!'* | ':^'* | ':('*exclude*')'*) ;;
    *)
      echo "$me: '$spec' is not an exclude pathspec. Write it as ':!:$spec'." >&2
      exit 2
      ;;
  esac
done

# Without a UTF-8 locale, PCRE rejects \x{2014} and git exits 128. Set one so
# the result does not depend on the machine.
out=$(LC_ALL=C.UTF-8 git grep -nIP '\x{2014}' -- . "$@" 2>&1)
status=$?

case $status in
  0)
    count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    echo "$me: found the em-dash (U+2014) on $count line(s):"
    echo
    printf '%s\n' "$out"
    echo
    echo "Method7 house style never uses U+2014. Replace each one with:"
    echo "  - a spaced en-dash (U+2013) for an aside"
    echo "  - otherwise a comma, colon or full stop"
    echo "  - an unspaced en-dash (U+2013) for a range: 2025–2026, Mon–Fri"
    exit 1
    ;;
  1)
    echo "$me: no em-dashes (U+2014) in tracked files."
    exit 0
    ;;
  *)
    echo "$me: the check could not run (git grep exited $status):" >&2
    printf '%s\n' "$out" >&2
    exit 2
    ;;
esac
