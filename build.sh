#!/usr/bin/env bash
# Git Bash / Unix: build all workspace packages in order.
# Use this if `npm run build` exits non-zero on Windows (npm lifecycle spawn quirk); otherwise prefer `npm run build`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/fnm-macos.sh"
ensure_fnm_on_macos

# @tailwindcss/oxide optional native packages are sometimes skipped (npm/cli#4828), especially after a Node switch.
ensure_tailwind_oxide_native() {
	if [[ ! -d "$SCRIPT_DIR/node_modules/@tailwindcss/oxide" ]]; then
		return 0
	fi
	if (cd "$SCRIPT_DIR" && node -e "require('@tailwindcss/oxide')" >/dev/null 2>&1); then
		return 0
	fi
	local ver
	ver="$(cd "$SCRIPT_DIR" && node -p "require('./node_modules/@tailwindcss/oxide/package.json').version" 2>/dev/null || true)"
	if [[ -z "$ver" ]]; then
		return 0
	fi
	echo "build.sh: @tailwindcss/oxide native binding missing; installing platform optional package..." >&2
	local pa
	pa="$(cd "$SCRIPT_DIR" && node -p "process.platform + '-' + process.arch")"
	case "$pa" in
		darwin-arm64) (cd "$SCRIPT_DIR" && npm install --no-save "@tailwindcss/oxide-darwin-arm64@${ver}") ;;
		darwin-x64) (cd "$SCRIPT_DIR" && npm install --no-save "@tailwindcss/oxide-darwin-x64@${ver}") ;;
		win32-x64) (cd "$SCRIPT_DIR" && npm install --no-save "@tailwindcss/oxide-win32-x64-msvc@${ver}") ;;
		win32-arm64) (cd "$SCRIPT_DIR" && npm install --no-save "@tailwindcss/oxide-win32-arm64-msvc@${ver}") ;;
		linux-x64) (cd "$SCRIPT_DIR" && npm install --no-save "@tailwindcss/oxide-linux-x64-gnu@${ver}") ;;
		linux-arm64) (cd "$SCRIPT_DIR" && npm install --no-save "@tailwindcss/oxide-linux-arm64-gnu@${ver}") ;;
		*) (cd "$SCRIPT_DIR" && npm install) ;;
	esac
	if ! (cd "$SCRIPT_DIR" && node -e "require('@tailwindcss/oxide')" >/dev/null 2>&1); then
		echo "build.sh: @tailwindcss/oxide still fails. Remove node_modules (and workspaces node_modules), then npm install." >&2
		exit 1
	fi
}

BIN="$SCRIPT_DIR/node_modules/.bin"
if [[ ! -e "$BIN/tsgo" && ! -e "$BIN/tsgo.cmd" ]]; then
	echo "build.sh: dependencies missing; running npm install in repo root..." >&2
	(cd "$SCRIPT_DIR" && npm install)
	if [[ ! -e "$BIN/tsgo" && ! -e "$BIN/tsgo.cmd" ]]; then
		echo "build.sh: still no node_modules/.bin/tsgo after npm install; fix install errors and retry." >&2
		exit 1
	fi
fi
cd "$SCRIPT_DIR/packages/tui" && "$BIN/tsgo" -p tsconfig.build.json
cd "$SCRIPT_DIR/packages/ai" && "$BIN/tsx" scripts/generate-models.ts && "$BIN/tsgo" -p tsconfig.build.json
cd "$SCRIPT_DIR/packages/agent" && "$BIN/tsgo" -p tsconfig.build.json
cd "$SCRIPT_DIR/packages/coding-agent" && "$BIN/tsgo" -p tsconfig.build.json
"$BIN/shx" chmod +x "$SCRIPT_DIR/packages/coding-agent/dist/cli.js" 2>/dev/null || true
cd "$SCRIPT_DIR/packages/coding-agent" && "$BIN/shx" mkdir -p dist/modes/interactive/theme && "$BIN/shx" cp src/modes/interactive/theme/*.json dist/modes/interactive/theme/ && "$BIN/shx" mkdir -p dist/core/export-html/vendor && "$BIN/shx" cp src/core/export-html/template.html src/core/export-html/template.css src/core/export-html/template.js dist/core/export-html/ && "$BIN/shx" cp src/core/export-html/vendor/*.js dist/core/export-html/vendor/
cd "$SCRIPT_DIR/packages/mom" && "$BIN/tsgo" -p tsconfig.build.json
"$BIN/shx" chmod +x "$SCRIPT_DIR/packages/mom/dist/main.js" 2>/dev/null || true
ensure_tailwind_oxide_native
cd "$SCRIPT_DIR/packages/web-ui" && "$BIN/tsc" -p tsconfig.build.json && "$BIN/tailwindcss" -i ./src/app.css -o ./dist/app.css --minify
cd "$SCRIPT_DIR/packages/pods" && "$BIN/tsgo" -p tsconfig.build.json
"$BIN/shx" chmod +x "$SCRIPT_DIR/packages/pods/dist/cli.js" 2>/dev/null || true
cd "$SCRIPT_DIR/packages/pods" && "$BIN/shx" cp src/models.json dist/ && "$BIN/shx" cp -r scripts dist/
echo "build.sh: done."
