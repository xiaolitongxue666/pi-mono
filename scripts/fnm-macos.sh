#!/usr/bin/env bash
# macOS: use fnm-managed Node (repo engines) when fnm is available.
# Caller must set SCRIPT_DIR to the repo root before sourcing, then call ensure_fnm_on_macos.
ensure_fnm_on_macos() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		return 0
	fi
	local fnm_bin=""
	if command -v fnm >/dev/null 2>&1; then
		fnm_bin="$(command -v fnm)"
	elif [[ -x "${HOME}/.local/share/fnm/fnm" ]]; then
		fnm_bin="${HOME}/.local/share/fnm/fnm"
	elif [[ -x "/opt/homebrew/bin/fnm" ]]; then
		fnm_bin="/opt/homebrew/bin/fnm"
	elif [[ -x "/usr/local/bin/fnm" ]]; then
		fnm_bin="/usr/local/bin/fnm"
	fi
	if [[ -z "$fnm_bin" ]]; then
		return 0
	fi
	eval "$("$fnm_bin" env)"
	if [[ -f "$SCRIPT_DIR/.node-version" || -f "$SCRIPT_DIR/.nvmrc" ]]; then
		(cd "$SCRIPT_DIR" && "$fnm_bin" use --install-if-missing)
	else
		(cd "$SCRIPT_DIR" && "$fnm_bin" use --install-if-missing 22)
	fi
}
