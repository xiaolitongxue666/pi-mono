/** Hooks for lazy-module-load-probe: track when provider SDK modules are actually loaded. */
/** @type {import("node:worker_threads").MessagePort | undefined} */
let notifyPort;

const targets = new Set([
	"@anthropic-ai/sdk",
	"openai",
	"@google/genai",
	"@mistralai/mistralai",
	"@aws-sdk/client-bedrock-runtime",
]);

/** @param {{ notifyPort?: import("node:worker_threads").MessagePort }} data */
export async function initialize(data) {
	notifyPort = data?.notifyPort;
}

function notify(specifier) {
	notifyPort?.postMessage({ type: "record", specifier });
}

function recordFromUrl(url) {
	const u = String(url);
	if (u.includes("@anthropic-ai") && u.includes("sdk")) {
		notify("@anthropic-ai/sdk");
		return;
	}
	if (u.includes("node_modules/openai") || u.includes(String.raw`node_modules\openai`)) {
		notify("openai");
		return;
	}
	if (u.includes("@google/genai") || u.includes(String.raw`node_modules\@google\genai`)) {
		notify("@google/genai");
		return;
	}
	if (u.includes("@mistralai/mistralai")) {
		notify("@mistralai/mistralai");
		return;
	}
	if (u.includes("@aws-sdk/client-bedrock-runtime")) {
		notify("@aws-sdk/client-bedrock-runtime");
	}
}

export async function resolve(specifier, context, nextResolve) {
	if (targets.has(specifier)) {
		notify(specifier);
	} else if (specifier.startsWith("@anthropic-ai/sdk")) {
		notify("@anthropic-ai/sdk");
	} else if (specifier === "openai" || specifier.startsWith("openai/")) {
		notify("openai");
	} else if (specifier.startsWith("@google/genai")) {
		notify("@google/genai");
	} else if (specifier.startsWith("@mistralai/mistralai")) {
		notify("@mistralai/mistralai");
	} else if (specifier.startsWith("@aws-sdk/client-bedrock-runtime")) {
		notify("@aws-sdk/client-bedrock-runtime");
	}
	return nextResolve(specifier, context);
}

export async function load(url, context, nextLoad) {
	const result = await nextLoad(url, context);
	recordFromUrl(url);
	return result;
}
