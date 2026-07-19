#!/usr/bin/env bash
# Recomputes the sha256s in Formula/bckupx-agent.rb against a just-published
# GitHub release's assets and bumps the version line. Run from the repo root
# after release.yml has finished uploading assets for the tag, e.g.:
#
#   ./update-formula.sh 0.1.1
#
# Then commit and push - see README.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA="$SCRIPT_DIR/Formula/bckupx-agent.rb"
REPO="Lekejosh/backupx-agent"

VERSION="${1:?usage: $(basename "$0") <version, e.g. 0.1.1>}"
VERSION="${VERSION#v}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

declare -A ASSETS=(
  [mac-arm]="bckupx-agent-macos-aarch64.tar.gz"
  [mac-intel]="bckupx-agent-macos-x86_64.tar.gz"
  [linux-arm]="bckupx-agent-linux-aarch64.tar.gz"
  [linux-intel]="bckupx-agent-linux-x86_64.tar.gz"
)

declare -A SHAS

for key in "${!ASSETS[@]}"; do
  asset="${ASSETS[$key]}"
  url="https://github.com/${REPO}/releases/download/v${VERSION}/${asset}"
  echo "==> Downloading $url"
  curl -fsSL -o "$TMP_DIR/$asset" "$url"
  SHAS[$key]="$(shasum -a 256 "$TMP_DIR/$asset" | awk '{print $1}')"
  echo "    sha256: ${SHAS[$key]}"
done

sed -i.bak \
  -e "s/^  version \".*\"/  version \"${VERSION}\"/" \
  "$FORMULA"

# Each on_arm/on_intel block has its own sha256 line, in the same order as
# ASSETS is iterated in the formula file itself (mac-arm, mac-intel,
# linux-arm, linux-intel) - replace them positionally with awk rather than
# matching on the placeholder text, since after the first run they're real
# hashes, not REPLACE_WITH_SHA256, and would no longer be a stable anchor.
awk -v arm_mac="${SHAS[mac-arm]}" -v intel_mac="${SHAS[mac-intel]}" \
    -v arm_linux="${SHAS[linux-arm]}" -v intel_linux="${SHAS[linux-intel]}" '
  /sha256 "/ {
    n++
    if (n == 1) sub(/sha256 ".*"/, "sha256 \"" arm_mac "\"")
    else if (n == 2) sub(/sha256 ".*"/, "sha256 \"" intel_mac "\"")
    else if (n == 3) sub(/sha256 ".*"/, "sha256 \"" arm_linux "\"")
    else if (n == 4) sub(/sha256 ".*"/, "sha256 \"" intel_linux "\"")
  }
  { print }
' "$FORMULA.bak" > "$FORMULA"
rm -f "$FORMULA.bak"

echo "==> Updated $FORMULA to version ${VERSION} with fresh sha256s"
