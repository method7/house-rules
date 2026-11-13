#!/bin/sh
# Tests for scripts/check-house-style.sh. Plain sh, no Node.
#
#   sh tests/check-house-style.test.sh
#
# The em-dash is never written in this file, nor a comma before "and" or a
# sentence starting with "And". They are made at run time with printf, so
# this repository passes its own check.

set -u

root=$(cd "$(dirname "$0")/.." && pwd)
check="$root/scripts/check-house-style.sh"
workflow="$root/.github/workflows/house-style.yml"
dash=$(printf '\342\200\224')
comma=','
cap=A

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

# expect <name> <wanted exit code> <directory> [args...]
# Runs the check in <directory>; output is left in $work/out.
expect() {
  name=$1 want=$2 dir=$3
  shift 3
  (cd "$dir" && sh "$check" "$@") > "$work/out" 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    pass "$name"
  else
    fail "$name (wanted exit $want, got $got)"
    sed 's/^/     | /' "$work/out"
  fi
}

# new_repo <name>: an empty git repository to plant files in.
new_repo() {
  git init -q "$work/$1"
  echo "$work/$1"
}

# 1. This repository is clean.
# The MIT licence is legal text, kept word for word, so it is excluded here
# exactly as this repository's CI excludes it.
expect "this repository passes its own check" 0 "$root" ':!:LICENSE'

# 2. A tracked file containing U+2014 fails and the output names it.
repo=$(new_repo dirty)
printf 'An aside %s like this.\n' "$dash" > "$repo/copy.md"
printf 'Nothing wrong here.\n' > "$repo/clean.md"
git -C "$repo" add copy.md clean.md
expect "a tracked file with an em-dash fails" 1 "$repo"
if grep -q '^copy\.md:1:' "$work/out"; then
  pass "the failure names the file and line"
else
  fail "the failure names the file and line"
  sed 's/^/     | /' "$work/out"
fi
if grep -q 'clean\.md' "$work/out"; then
  fail "a clean file is not reported"
else
  pass "a clean file is not reported"
fi

# 3. It also fails when run from a subfolder: it checks the whole tree.
mkdir "$repo/sub"
expect "run from a subfolder, it still checks the whole tree" 1 "$repo/sub"

# 4. An em-dash in a code comment counts too: the ban applies everywhere.
repo=$(new_repo comment)
printf '#!/bin/sh\n# a comment %s with an aside\necho hi\n' "$dash" > "$repo/run.sh"
git -C "$repo" add run.sh
expect "an em-dash in a code comment fails" 1 "$repo"

# 5. An exclude pathspec skips that folder and only that folder.
repo=$(new_repo exclude)
mkdir "$repo/legacy-v1"
printf 'Old copy %s kept as it was.\n' "$dash" > "$repo/legacy-v1/old.md"
printf 'New copy.\n' > "$repo/new.md"
git -C "$repo" add legacy-v1/old.md new.md
expect "without an exclude, the legacy folder fails" 1 "$repo"
expect "':!:legacy-v1' excludes it" 0 "$repo" ':!:legacy-v1'
expect "':(exclude)legacy-v1' excludes it" 0 "$repo" ':(exclude)legacy-v1'
printf 'New copy %s again.\n' "$dash" > "$repo/new.md"
expect "an exclude does not hide other files" 1 "$repo" ':!:legacy-v1'

# 6. A pathspec that is not an exclude is refused, not used to narrow the check.
expect "a plain path argument is refused" 2 "$repo" 'new.md'

# 7. An untracked file is not checked (git grep reads tracked files only).
repo=$(new_repo untracked)
printf 'Scratch %s notes.\n' "$dash" > "$repo/scratch.md"
expect "an untracked file is ignored" 0 "$repo"

# 8. Outside a git work tree the check refuses to pass.
mkdir "$work/not-a-repo"
expect "outside a git work tree it exits 2, not 0" 2 "$work/not-a-repo"

# 9. A comma before "and" fails. So does one split across two lines.
repo=$(new_repo comma)
printf 'Fast%s and easy to check.\n' "$comma" > "$repo/copy.md"
git -C "$repo" add copy.md
expect "a comma before and fails" 1 "$repo"
if grep -q '^copy\.md:1:' "$work/out"; then
  pass "the comma failure names the file and line"
else
  fail "the comma failure names the file and line"
  sed 's/^/     | /' "$work/out"
fi
printf 'Fast%s\nand easy to check.\n' "$comma" > "$repo/copy.md"
expect "a comma at a line end before and on the next line fails" 1 "$repo"
printf 'Fast%s\n- and a list item.\n' "$comma" > "$repo/copy.md"
expect "the split is caught across a list marker too" 1 "$repo"
printf 'Fast%s\n\nand a new paragraph.\n' "$comma" > "$repo/copy.md"
expect "a blank line between them is not a split sentence" 0 "$repo"

# 10. A sentence that starts with "And" fails, at a line start or mid-line.
printf '%snd that is that.\n' "$cap" > "$repo/copy.md"
expect "a line starting with And fails" 1 "$repo"
printf 'Done. %snd then more.\n' "$cap" > "$repo/copy.md"
expect "And after a full stop fails" 1 "$repo"
printf '"%snd so on."\n' "$cap" > "$repo/copy.md"
expect "And after an opening quote fails" 1 "$repo"

# 11. Words that only look like the mistake pass.
printf 'Red%s green and blue. Andrew%s Andover and android%s andante.\nfoo(a%sb) and bar\n' "$comma" "$comma" "$comma" "$comma" > "$repo/copy.md"
expect "a list without the comma passes, as do words starting with and" 0 "$repo"

# 12. An exclude pathspec skips the comma check too.
mkdir -p "$repo/legal"
printf 'Copy%s modify%s and merge.\n' "$comma" "$comma" > "$repo/legal/LICENSE"
git -C "$repo" add legal/LICENSE
expect "a licence with the comma fails without an exclude" 1 "$repo"
expect "':!:legal' excludes it from the comma check" 0 "$repo" ':!:legal'

# 13. The workflow runs exactly this script.
awk '
  index($0, "<<'\''END_OF_HOUSE_RULES_SCRIPT'\''") {
    match($0, /^ */); ind = RLENGTH; on = 1; next
  }
  on && /^ *END_OF_HOUSE_RULES_SCRIPT$/ { exit }
  on { print substr($0, ind + 1) }
' "$workflow" > "$work/inlined.sh"
if [ -s "$work/inlined.sh" ] && cmp -s "$check" "$work/inlined.sh"; then
  pass "the workflow's inlined script matches scripts/check-house-style.sh"
else
  fail "the workflow's inlined script matches scripts/check-house-style.sh (run scripts/sync-workflow.sh)"
  diff "$check" "$work/inlined.sh" | sed 's/^/     | /'
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failures test(s) failed."
  exit 1
fi
