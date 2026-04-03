#!/usr/bin/env bash
# Run workspace package tests without nested `npm run` (avoids npm spawn issues on Windows + Git Bash).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$REPO_ROOT/node_modules/.bin"
if [[ ! -e "$BIN/vitest" && ! -e "$BIN/vitest.cmd" ]]; then
	echo "test-workspaces.sh: vitest not found under $BIN — run npm install from repo root." >&2
	exit 1
fi

echo "test-workspaces.sh: packages/ai"
(cd "$REPO_ROOT/packages/ai" && "$BIN/vitest" --run)

echo "test-workspaces.sh: packages/agent"
(cd "$REPO_ROOT/packages/agent" && "$BIN/vitest" --run)

echo "test-workspaces.sh: packages/coding-agent"
(cd "$REPO_ROOT/packages/coding-agent" && "$BIN/vitest" --run)

echo "test-workspaces.sh: packages/tui"
(cd "$REPO_ROOT/packages/tui" && node --test --import tsx test/*.test.ts)

echo "test-workspaces.sh: done."
