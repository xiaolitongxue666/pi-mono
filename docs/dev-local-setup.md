# Local development: repo layout, env, Windows / Git Bash

## Monorepo layout

| Path | Role |
|------|------|
| `packages/ai` | Multi-provider LLM API (`@mariozechner/pi-ai`) |
| `packages/agent` | Agent runtime (`@mariozechner/pi-agent-core`) |
| `packages/coding-agent` | Interactive pi CLI (`@mariozechner/pi-coding-agent`) |
| `packages/tui` | Terminal UI library |
| `packages/web-ui` | Web chat components; `example/` is a Vite demo |
| `packages/mom`, `packages/pods` | Other shipped tools |
| `extensions/volc-ark` | Optional extension: Volcengine ARK (方舟) OpenAI-compatible + `volc-deepseek` provider |
| `build.sh` | Bash build (avoids nested `npm run` issues on some Windows setups) |
| `scripts/test-workspaces.sh`, `scripts/check-workspaces.sh` | Tests / check without nested `npm run` |
| `pi-test.sh` | Run pi from source via `tsx` + `packages/coding-agent/src/cli.ts` |
| `start-pi.sh` | Loads `.env`, optional proxy, auto-attaches `extensions/volc-ark`, then runs `pi-test.sh` |

## Build and check

From the repo root (Git Bash recommended on Windows):

```bash
npm install
bash build.sh
bash scripts/check-workspaces.sh
./test.sh
```

`npm run build` / `npm run check` / `npm test` call the same bash scripts on POSIX shells.

## Volcengine ARK (火山方舟) + `.env`

1. Copy [`.env.example`](../.env.example) to **`.env`** in the repo root (gitignored).
2. Set **`VOLC_API_KEY`** or **`ARK_API_KEY`**.
3. Set a **full** inference endpoint id: **`VOLC_ARK_ENDPOINT=ep-...`** or **`DEFAULT_MODEL=ep-...`** (from the Ark console). Placeholder `ep-` alone is invalid and yields HTTP **404** from the API.
4. Optional: **`VOLC_BASE_URL`** (default Beijing ARK OpenAI-compatible base is in `.env.example`).

Start pi (loads `.env` and the volc extension):

```bash
bash start-pi.sh
bash start-pi.sh --print --provider volc-deepseek "hello"
```

To create `.env` from the example in one step: `INIT_ENV=1 bash start-pi.sh` (see `start-pi.sh` header).

## Common issues

### `npm` / lifecycle: `spawn` / `The "file" argument must be of type string. Received undefined`

Seen on **Windows + Git Bash** when npm resolves `script-shell` / `ComSpec` incorrectly. Prefer **`bash build.sh`** and direct **`node_modules/.bin/...`** invocations instead of deep **`npm run`** chains.

### `npm install` exits non-zero on `prepare` / `husky`

If `husky` fails locally, you can use `npm install --ignore-scripts` for a working `node_modules`, then run `bash build.sh`.

### `404 The model or endpoint ep- does not exist`

The configured endpoint id was the placeholder **`ep-`** or wrong id. Use the **full** `ep-...` string from the Ark console.

### `start-pi.sh` / `--print` seems to produce no output for a long time

Cold `tsx` startup can take **10–30s** on Windows. If it never returns, check network access to `VOLC_BASE_URL`, firewall, and that the endpoint id is valid.

### Vitest stuck after `RUN v3.2.4` (packages/ai)

Separate from running pi: Vitest worker/pool behavior on some Windows setups. Try `vitest run --poolOptions.forks.singleFork=true` or `--pool=threads` per [Vitest docs](https://vitest.dev/config/). Not required for `bash start-pi.sh`.

### Web UI example

```bash
cd packages/web-ui/example
../../../node_modules/.bin/vite --host 127.0.0.1 --port 5173
```

Browser keys are stored locally; Volc ARK is not a built-in named row—use **Custom provider** in Settings or CLI/env for the coding agent.

## See also

- [packages/coding-agent/docs/windows.md](../packages/coding-agent/docs/windows.md) — shell requirements for pi
- [extensions/volc-ark/index.ts](../extensions/volc-ark/index.ts) — env vars read by the extension
