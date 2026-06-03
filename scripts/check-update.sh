#!/usr/bin/env bash
# Detect whether upstream HelpWire Operator is newer than the version this PKGBUILD pins.
#
# Source of truth = the app's own auto-update manifest (the endpoint the binary itself
# polls), not the marketing website. Prints the upstream version and sets exit status:
#   0  -> up to date (pkgver == upstream)
#   10 -> update available (prints UPSTREAM version to stdout)
#   1  -> error (couldn't fetch / parse)
#
# In CI this drives the auto-bump job. Run locally any time to check by hand.
set -euo pipefail

MANIFEST_URL="https://get.helpwire.app/downloads/operator/linux/update/settings.xml"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKGBUILD="${REPO_ROOT}/PKGBUILD"

err() { echo "check-update: $*" >&2; }

# Current pinned version
local_ver="$(sed -n 's/^pkgver=//p' "$PKGBUILD" | head -1)"
[ -n "$local_ver" ] || { err "could not read pkgver from $PKGBUILD"; exit 1; }

# Upstream version from the auto-update manifest
manifest="$(curl -fsSL "$MANIFEST_URL")" || { err "failed to fetch manifest"; exit 1; }
upstream_ver="$(printf '%s' "$manifest" \
    | grep -oE '<current_version>[^<]+</current_version>' \
    | sed -E 's:</?current_version>::g' | head -1)"
[ -n "$upstream_ver" ] || { err "could not parse current_version from manifest"; exit 1; }

echo "local=${local_ver} upstream=${upstream_ver}" >&2

if [ "$local_ver" = "$upstream_ver" ]; then
    echo "$upstream_ver"
    exit 0
fi

# Newer (or simply different) — treat any mismatch as "update available".
echo "$upstream_ver"
exit 10
