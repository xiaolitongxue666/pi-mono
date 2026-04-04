#!/usr/bin/env bash
# Run pi from source: repo root tsx -> packages/coding-agent/src/cli.ts
# Loads repo root .env when present (skipped with --no-env). See docs/dev-local-setup.md for .env and Windows notes.
#
set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/fnm-macos.sh"
ensure_fnm_on_macos

# Check for --no-env flag
NO_ENV=false
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--no-env" ]]; then
    NO_ENV=true
  else
    ARGS+=("$arg")
  fi
done

# Repo root `.env` (gitignored): export vars before pi starts. Skip when --no-env.
if [[ "$NO_ENV" != "true" && -f "$SCRIPT_DIR/.env" ]]; then
	set -a
	# shellcheck disable=SC1091
	source "$SCRIPT_DIR/.env"
	set +a
fi

if [[ "$NO_ENV" == "true" ]]; then
  # Unset API keys (see packages/ai/src/env-api-keys.ts)
  unset ANTHROPIC_API_KEY
  unset ANTHROPIC_OAUTH_TOKEN
  unset OPENAI_API_KEY
  unset GEMINI_API_KEY
  unset GROQ_API_KEY
  unset CEREBRAS_API_KEY
  unset XAI_API_KEY
  unset OPENROUTER_API_KEY
  unset ZAI_API_KEY
  unset MISTRAL_API_KEY
  unset MINIMAX_API_KEY
  unset MINIMAX_CN_API_KEY
  unset AI_GATEWAY_API_KEY
  unset OPENCODE_API_KEY
  unset COPILOT_GITHUB_TOKEN
  unset GH_TOKEN
  unset GITHUB_TOKEN
  unset GOOGLE_APPLICATION_CREDENTIALS
  unset GOOGLE_CLOUD_PROJECT
  unset GCLOUD_PROJECT
  unset GOOGLE_CLOUD_LOCATION
  unset AWS_PROFILE
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_REGION
  unset AWS_DEFAULT_REGION
  unset AWS_BEARER_TOKEN_BEDROCK
  unset AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
  unset AWS_CONTAINER_CREDENTIALS_FULL_URI
  unset AWS_WEB_IDENTITY_TOKEN_FILE
  unset AZURE_OPENAI_API_KEY
  unset AZURE_OPENAI_BASE_URL
  unset AZURE_OPENAI_RESOURCE_NAME
  unset ARK_API_KEY
  unset VOLC_API_KEY
  unset VOLC_BASE_URL
  unset VOLC_ARK_ENDPOINT
  unset VOLC_ARK_ENDPOINT_R1
  echo "Running without API keys..."
fi

TSX_BIN="$SCRIPT_DIR/node_modules/.bin/tsx"
if [[ ! -e "$TSX_BIN" && ! -e "$TSX_BIN.cmd" ]]; then
  echo "tsx not found at $TSX_BIN. Run npm install from the repo root first." >&2
  exit 1
fi

"$TSX_BIN" "$SCRIPT_DIR/packages/coding-agent/src/cli.ts" ${ARGS[@]+"${ARGS[@]}"}
