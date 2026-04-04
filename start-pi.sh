#!/usr/bin/env bash
# One-launch helper for pi from this repo (Git Bash / macOS / Linux).
#
# - Sources repo root .env when present (export all vars).
# - Optionally enables HTTP(S) proxy when USE_PROXY=1 or PI_USE_PROXY=1.
# - Passes -e extensions/volc-ark/index.ts so Volcengine ARK "volc-deepseek" is registered.
# - Delegates to pi-test.sh (tsx + packages/coding-agent/src/cli.ts).
#
# First-time .env:  cp .env.example .env  then set VOLC_API_KEY and full VOLC_ARK_ENDPOINT=ep-...
# Or: INIT_ENV=1 bash start-pi.sh  copies .env.example -> .env if missing.
#
# Common failures: see docs/dev-local-setup.md (404 on ep-, npm spawn on Windows, husky prepare).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
EXAMPLE_ENV="$SCRIPT_DIR/.env.example"
VOLC_EXT="$SCRIPT_DIR/extensions/volc-ark/index.ts"

# Optional: USE_PROXY=1 or PI_USE_PROXY=1 (Git Bash / macOS / Linux; override URL with PROXY_URL)
if [[ "${USE_PROXY:-}" == "1" || "${PI_USE_PROXY:-}" == "1" ]]; then
	PROXY_URL="${PROXY_URL:-http://127.0.0.1:7890}"
	export http_proxy="$PROXY_URL" https_proxy="$PROXY_URL"
	export HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL"
	export all_proxy="$PROXY_URL" ALL_PROXY="$PROXY_URL"
	echo "start-pi.sh: proxy enabled ($PROXY_URL)" >&2
fi

if [[ ! -f "$ENV_FILE" ]]; then
	if [[ "${INIT_ENV:-}" == "1" && -f "$EXAMPLE_ENV" ]]; then
		cp "$EXAMPLE_ENV" "$ENV_FILE"
		echo "start-pi.sh: created $ENV_FILE from .env.example — edit VOLC_API_KEY and VOLC_ARK_ENDPOINT (full ep-...)." >&2
	elif [[ -f "$EXAMPLE_ENV" ]]; then
		echo "start-pi.sh: no .env at $ENV_FILE — copy:  cp .env.example .env  (or INIT_ENV=1 to auto-copy)" >&2
	fi
else
	set -a
	# shellcheck disable=SC1091
	source "$ENV_FILE"
	set +a
fi

# Warn when Volc key is set but endpoint is missing or placeholder (API returns 404 for model id "ep-").
__volc_primary="${VOLC_ARK_ENDPOINT:-}"
if [[ -z "$__volc_primary" ]]; then
	__volc_primary="${DEFAULT_MODEL:-}"
fi
if [[ -n "${VOLC_API_KEY:-}${ARK_API_KEY:-}" && -f "$VOLC_EXT" ]]; then
	if [[ -z "${__volc_primary// /}" ]]; then
		echo "start-pi.sh: VOLC_API_KEY/ARK_API_KEY set but neither VOLC_ARK_ENDPOINT nor DEFAULT_MODEL — set full ep-... from Ark console (docs/dev-local-setup.md)." >&2
	elif [[ "$__volc_primary" == "ep-" ]] || [[ ${#__volc_primary} -le 4 ]]; then
		echo "start-pi.sh: VOLC_ARK_ENDPOINT/DEFAULT_MODEL must be full endpoint id from console, not placeholder ep- — docs/dev-local-setup.md." >&2
	fi
fi
unset __volc_primary

EXTRA_ARGS=()
if [[ -f "$VOLC_EXT" ]]; then
	EXTRA_ARGS+=(-e "$VOLC_EXT")
fi

exec "$SCRIPT_DIR/pi-test.sh" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} "$@"
