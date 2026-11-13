#!/bin/sh
# check-house-style.sh: fail if any tracked file breaks the punctuation rules:
# an em-dash (U+2014), a comma straight before "and", or a sentence that
# starts with "And".
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
# Why git grep and not grep: macOS grep has no -P. A grep that fails to
# run prints nothing, which looks exactly like a pass. git grep behaves the
# same on every machine and only reads tracked files.
#
# Exit codes: 0 clean, 1 something found, 2 the check could not run.
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

found=0
broken=0

# 1. The em-dash.
#
# Without a UTF-8 locale, PCRE rejects \x{2014} and git exits 128. Set one so
# the result does not depend on the machine.
out=$(LC_ALL=C.UTF-8 git grep -nIP '\x{2014}' -- . "$@" 2>&1)
status=$?

case $status in
  0)
    found=1
    count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    echo "$me: found the em-dash (U+2014) on $count line(s):"
    echo
    printf '%s\n' "$out"
    echo
    echo "Method7 house style never uses U+2014. Replace each one with:"
    echo "  - a spaced en-dash (U+2013) for an aside"
    echo "  - otherwise a comma, colon or full stop"
    echo "  - an unspaced en-dash (U+2013) for a range: 2025–2026, Mon–Fri"
    echo
    ;;
  1)
    echo "$me: no em-dashes (U+2014) in tracked files."
    ;;
  *)
    broken=1
    echo "$me: the em-dash check could not run (git grep exited $status):" >&2
    printf '%s\n' "$out" >&2
    ;;
esac

# 2. A comma before "and" or a sentence that starts with "And".
#
# git grep reads one line at a time, but a comma at the end of one line and
# "and" at the start of the next is the same mistake, so awk reads each file
# whole. git grep still chooses the files: tracked, not binary and not
# excluded.
list=$(mktemp) || exit 2
trap 'rm -f "$list"' EXIT

if git grep -Ilz -e '' -- . "$@" > "$list" 2>/dev/null; then
  :
else
  status=$?
  # Exit 1 means no text files at all, which is clean.
  if [ "$status" -ne 1 ]; then
    broken=1
    echo "$me: the comma check could not list files (git grep exited $status)." >&2
  fi
fi

out=
if [ "$broken" -eq 0 ] && [ -s "$list" ]; then
  out=$(xargs -0 awk '
    FNR == 1 { prev = "" }
    {
      if ($0 ~ /,[ \t]*and([^A-Za-z0-9_]|$)/ ||
          (prev ~ /,[ \t]*$/ && $0 ~ /^[ \t>*_-]*and([^A-Za-z0-9_]|$)/) ||
          $0 ~ /^[ \t]*[^A-Za-z0-9 \t]*And([^A-Za-z0-9_]|$)/ ||
          $0 ~ /[.!?][^A-Za-z0-9 \t]*[ \t]+[^A-Za-z0-9 \t]*And([^A-Za-z0-9_]|$)/)
        print FILENAME ":" FNR ":" $0
      prev = $0
    }
  ' < "$list") || {
    broken=1
    echo "$me: the comma check could not run (awk failed)." >&2
  }
fi

if [ -n "$out" ]; then
  found=1
  count=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  echo "$me: found a comma before \"and\", or a sentence starting with \"And\", on $count line(s):"
  echo
  printf '%s\n' "$out"
  echo
  echo "Method7 house style never puts a comma before \"and\". It never starts"
  echo "a sentence with \"And\" either. The \"and\" already joins the words, so:"
  echo "  - in a list, drop the comma: red, green and blue"
  echo "  - between two sentences, drop the comma or end the first sentence"
elif [ "$broken" -eq 0 ]; then
  echo "$me: no comma before \"and\" and no sentence starting with \"And\"."
fi

if [ "$broken" -ne 0 ]; then
  exit 2
fi
exit "$found"
