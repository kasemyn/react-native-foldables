#!/usr/bin/env bash
set -eu
E="$1"
rm -rf "$E/blind" && mkdir -p "$E/blind" "$E/key"
: > "$E/key/key.txt"
sanitize() {
  sed -E \
    -e 's/\(?(see )?\[?(RULES|STATUS|SKILL)(\.md)?\]?(\([^)]*\))?[[:space:]]*§[[:space:]]*[0-9]+(–[0-9]+)?\)?//g' \
    -e 's/\(?(see )?\[?(RULES|STATUS|SKILL)\.md\]?(\([^)]*\))?\)?//g' \
    -e 's/§[[:space:]]*[0-9]+//g' \
    -e 's/react-native-foldables( skill)?/the guide/g' \
    -e 's/(scripts\/)?audit\.sh/a static check/g' \
    -e 's/[Tt]he skill/the guide/g' \
    -e 's/[Ss]kill/guide/g' \
    "$1"
}
for n in 1 2 3 4 5; do
  if [ $((RANDOM % 2)) -eq 0 ]; then x=A; y=B; else x=B; y=A; fi
  echo "e$n X=$x Y=$y" >> "$E/key/key.txt"
  sanitize "$E/runs/e$n-$x.md" > "$E/blind/e$n-X.md"
  sanitize "$E/runs/e$n-$y.md" > "$E/blind/e$n-Y.md"
done
