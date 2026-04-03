/**
 * Subprocess entry for lazy-module-load.test.ts.
 * Preload: lazy-module-register.mjs (before tsx) so loader hooks apply to tsx-resolved modules.
 */
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packageRoot = resolve(__dirname, "..");
const aiEntryUrl = pathToFileURL(resolve(packageRoot, "src/index.ts")).href;

const mod = await import(aiEntryUrl);
const mode = process.argv[2] ?? "empty";

const abortQuickly = { signal: AbortSignal.timeout(8000) };

if (mode === "anthropic") {
	const model = {
		id: "claude-sonnet-4-20250514",
		name: "Claude Sonnet 4",
		api: "anthropic-messages" as const,
		provider: "anthropic",
		baseUrl: "https://api.anthropic.com",
		reasoning: true,
		input: ["text"] as const,
		cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
		contextWindow: 200000,
		maxTokens: 8192,
	};
	const context = { messages: [{ role: "user" as const, content: "hi" }] };
	await mod.streamSimpleAnthropic(model, context, abortQuickly).result();
} else if (mode === "dispatch") {
	const model = mod.getModel("anthropic", "claude-sonnet-4-20250514");
	const context = { messages: [{ role: "user" as const, content: "hi" }] };
	await mod.streamSimple(model, context, abortQuickly).result();
}

const probeGlobals = globalThis as typeof globalThis & { __lazyProbeLoaded?: string[] };
const loaded = probeGlobals.__lazyProbeLoaded ?? [];
console.log(JSON.stringify({ loadedSpecifiers: [...new Set(loaded)] }));
