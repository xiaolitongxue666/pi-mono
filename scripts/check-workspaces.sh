#!/usr/bin/env bash
# Mirrors root package.json `check` without nested `npm run` (Git Bash / Windows safe).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$REPO_ROOT/node_modules/.bin"
TSC="$REPO_ROOT/node_modules/typescript/bin/tsc"
if [[ ! -e "$BIN/biome" && ! -e "$BIN/biome.cmd" ]]; then
	echo "check-workspaces.sh: biome not found under $BIN — run npm install from repo root." >&2
	exit 1
fi
if [[ ! -f "$TSC" ]]; then
	echo "check-workspaces.sh: TypeScript CLI not found at $TSC — run npm install from repo root." >&2
	exit 1
fi

cd "$REPO_ROOT"
echo "check-workspaces.sh: biome (repo root)"
"$BIN/biome" check --write --error-on-warnings .

echo "check-workspaces.sh: tsgo --noEmit (repo root)"
"$BIN/tsgo" --noEmit

echo "check-workspaces.sh: browser-smoke"
node "$REPO_ROOT/scripts/check-browser-smoke.mjs"

echo "check-workspaces.sh: packages/web-ui"
cd "$REPO_ROOT/packages/web-ui"
"$BIN/biome" check --write --error-on-warnings .
node "$TSC" --noEmit

echo "check-workspaces.sh: packages/web-ui/example"
cd "$REPO_ROOT/packages/web-ui/example"
"$BIN/biome" check --write --error-on-warnings .
node "$TSC" --noEmit

echo "check-workspaces.sh: done."
