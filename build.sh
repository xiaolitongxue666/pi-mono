#!/usr/bin/env bash
# Git Bash / Unix: build all workspace packages in order.
# Use this if `npm run build` exits non-zero on Windows (npm lifecycle spawn quirk); otherwise prefer `npm run build`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$SCRIPT_DIR/node_modules/.bin"
if [[ ! -e "$BIN/tsgo" && ! -e "$BIN/tsgo.cmd" ]]; then
	echo "build.sh: run npm install from repo root first." >&2
	exit 1
fi
cd "$SCRIPT_DIR/packages/tui" && "$BIN/tsgo" -p tsconfig.build.json
cd "$SCRIPT_DIR/packages/ai" && "$BIN/tsx" scripts/generate-models.ts && "$BIN/tsgo" -p tsconfig.build.json
cd "$SCRIPT_DIR/packages/agent" && "$BIN/tsgo" -p tsconfig.build.json
cd "$SCRIPT_DIR/packages/coding-agent" && "$BIN/tsgo" -p tsconfig.build.json
"$BIN/shx" chmod +x "$SCRIPT_DIR/packages/coding-agent/dist/cli.js" 2>/dev/null || true
cd "$SCRIPT_DIR/packages/coding-agent" && "$BIN/shx" mkdir -p dist/modes/interactive/theme && "$BIN/shx" cp src/modes/interactive/theme/*.json dist/modes/interactive/theme/ && "$BIN/shx" mkdir -p dist/core/export-html/vendor && "$BIN/shx" cp src/core/export-html/template.html src/core/export-html/template.css src/core/export-html/template.js dist/core/export-html/ && "$BIN/shx" cp src/core/export-html/vendor/*.js dist/core/export-html/vendor/
cd "$SCRIPT_DIR/packages/mom" && "$BIN/tsgo" -p tsconfig.build.json
"$BIN/shx" chmod +x "$SCRIPT_DIR/packages/mom/dist/main.js" 2>/dev/null || true
cd "$SCRIPT_DIR/packages/web-ui" && "$BIN/tsc" -p tsconfig.build.json && "$BIN/tailwindcss" -i ./src/app.css -o ./dist/app.css --minify
cd "$SCRIPT_DIR/packages/pods" && "$BIN/tsgo" -p tsconfig.build.json
"$BIN/shx" chmod +x "$SCRIPT_DIR/packages/pods/dist/cli.js" 2>/dev/null || true
cd "$SCRIPT_DIR/packages/pods" && "$BIN/shx" cp src/models.json dist/ && "$BIN/shx" cp -r scripts dist/
echo "build.sh: done."
