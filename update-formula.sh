#!/usr/bin/env bash
# Points Formula/bckupx-agent.rb at an agent release: sets `version` and the
# four sha256s from that release's manifest at agents.bckupx.com (the same
# checksums the installers and the self-updater verify against).
#
#   ./update-formula.sh 0.1.42
#
# The agent's release workflow runs this and pushes the result on every
# stable tag; by hand, commit and push afterwards.
set -euo pipefail

FORMULA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Formula/bckupx-agent.rb"
BASE="${RELEASES_BASE:-https://agents.bckupx.com}"
VERSION="${1:?usage: $(basename "$0") <version, e.g. 0.1.42>}"
VERSION="${VERSION#v}"

manifest="$(curl -fsSL "$BASE/$VERSION/manifest.json")"
# Same order as the sha256 lines in the formula: mac-arm, mac-intel,
# linux-arm, linux (x86_64 glibc).
SHAS=()
for id in mac-arm mac-intel linux-arm linux; do
  sha="$(printf '%s' "$manifest" | jq -er --arg id "$id" '.artifacts[$id].sha256')"
  file="$(printf '%s' "$manifest" | jq -er --arg id "$id" '.artifacts[$id].file')"
  # The formula builds the URL from the version; make sure it's the one the
  # manifest names, and that it's there.
  if [ "$id" = linux ]; then expected="agent-linux-v$VERSION"; else expected="agent-$id-v$VERSION"; fi
  [ "$file" = "$expected" ] || {
    echo "error: $id is $file in the manifest, not what the formula expects" >&2
    exit 1
  }
  curl -fsSIL -o /dev/null "$BASE/$VERSION/$file"
  echo "$id: $sha"
  SHAS+=("$sha")
done

sed -e "s/^  version \".*\"/  version \"${VERSION}\"/" "$FORMULA" > "$FORMULA.bak"
awk -v s1="${SHAS[0]}" -v s2="${SHAS[1]}" -v s3="${SHAS[2]}" -v s4="${SHAS[3]}" '
  /sha256 "/ {
    n++
    s = (n == 1) ? s1 : (n == 2) ? s2 : (n == 3) ? s3 : s4
    sub(/sha256 "[^"]*"/, "sha256 \"" s "\"")
  }
  { print }
' "$FORMULA.bak" > "$FORMULA"
rm -f "$FORMULA.bak"
echo "==> Formula/bckupx-agent.rb now points at bckupx-agent ${VERSION}"
