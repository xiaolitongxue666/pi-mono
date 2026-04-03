/**
 * Registers provider `volc-deepseek` for Volcengine ARK OpenAI-compatible API.
 * Troubleshooting: docs/dev-local-setup.md (404 if endpoint is placeholder `ep-` only).
 *
 * Environment (repo `.env` or process env):
 * - API key: `VOLC_API_KEY` (preferred) or `ARK_API_KEY`
 * - Base URL: `VOLC_BASE_URL` or default Beijing ARK endpoint
 * - Primary model id (ep-...): `VOLC_ARK_ENDPOINT` or `DEFAULT_MODEL`
 * - Optional R1 slot: `VOLC_ARK_ENDPOINT_R1`
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const DEFAULT_VOLC_BASE = "https://ark.cn-beijing.volces.com/api/v3";

function resolveApiKeyEnvName(): string {
	const volc = process.env.VOLC_API_KEY?.trim() ?? "";
	const ark = process.env.ARK_API_KEY?.trim() ?? "";
	if (volc !== "") {
		return "VOLC_API_KEY";
	}
	if (ark !== "") {
		return "ARK_API_KEY";
	}
	return "VOLC_API_KEY";
}

function resolvePrimaryEndpoint(): string | undefined {
	const a = process.env.VOLC_ARK_ENDPOINT?.trim();
	if (a?.startsWith("ep-")) {
		return a;
	}
	const b = process.env.DEFAULT_MODEL?.trim();
	if (b?.startsWith("ep-")) {
		return b;
	}
	return undefined;
}

export default function (pi: ExtensionAPI) {
	const primaryEp = resolvePrimaryEndpoint();
	const r1Ep = process.env.VOLC_ARK_ENDPOINT_R1?.trim();
	const baseUrl = process.env.VOLC_BASE_URL?.trim() || DEFAULT_VOLC_BASE;

	const models: Array<{
		id: string;
		name: string;
		reasoning: boolean;
		input: ("text" | "image")[];
		cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
		contextWindow: number;
		maxTokens: number;
	}> = [];

	if (primaryEp) {
		models.push({
			id: primaryEp,
			name: "DeepSeek (Volcengine ARK)",
			reasoning: false,
			input: ["text"],
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
			contextWindow: 32768,
			maxTokens: 8192,
		});
	}

	if (r1Ep?.startsWith("ep-")) {
		models.push({
			id: r1Ep,
			name: "DeepSeek-R1 (Volcengine ARK)",
			reasoning: true,
			input: ["text"],
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
			contextWindow: 65536,
			maxTokens: 8192,
		});
	}

	if (models.length === 0) {
		return;
	}

	pi.registerProvider("volc-deepseek", {
		baseUrl,
		apiKey: resolveApiKeyEnvName(),
		authHeader: true,
		api: "openai-completions",
		models,
	});
}
