#!/bin/sh
# sync-workflow.sh: copy scripts/check-house-style.sh into the reusable
# workflow, between the heredoc markers, so the workflow runs exactly the
# script a developer runs locally.
#
# Run it after any change to the check script, and commit both files.
# tests/check-house-style.test.sh fails if the two copies differ.

set -eu

root=$(git rev-parse --show-toplevel)
cd "$root"

workflow=.github/workflows/house-style.yml
script=scripts/check-house-style.sh
marker=END_OF_HOUSE_RULES_SCRIPT
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk -v script="$script" -v marker="$marker" '
  # The opening line, cat > ... <<'\''MARKER'\''. Keep it, then write the
  # script indented to match it.
  index($0, "<<'\''" marker "'\''") {
    print
    match($0, /^ */)
    pad = substr($0, 1, RLENGTH)
    while ((getline line < script) > 0) {
      if (line == "") print ""; else print pad line
    }
    skipping = 1
    found = 1
    next
  }
  # The closing marker line ends the old copy.
  skipping && $0 ~ ("^ *" marker "$") { skipping = 0 }
  !skipping { print }
  END { if (!found) { print "sync-workflow: marker not found" > "/dev/stderr"; exit 1 } }
' "$workflow" > "$tmp"

cat "$tmp" > "$workflow"
echo "sync-workflow: copied $script into $workflow"
