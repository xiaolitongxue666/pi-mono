import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { describe, expect, it } from "vitest";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const testDir = dirname(fileURLToPath(import.meta.url));
const probeRegisterUrl = pathToFileURL(resolve(testDir, "lazy-module-register.mjs")).href;
/** Relative to packageRoot so Node does not concatenate cwd + file:// (Windows). */
const probeScriptRel = "test/lazy-module-load-probe.ts";

type ProbeResult = {
	loadedSpecifiers: string[];
};

function runProbe(mode: string): ProbeResult {
	const result = spawnSync(
		process.execPath,
		["--import", probeRegisterUrl, "--import", "tsx/esm", probeScriptRel, mode],
		{
			cwd: packageRoot,
			encoding: "utf8",
		},
	);

	if (result.status !== 0) {
		throw new Error(`Probe failed (exit ${result.status})\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}`);
	}

	const stdoutLines = result.stdout
		.split(/\r?\n/)
		.map((line) => line.trim())
		.filter((line) => line.length > 0);
	const lastLine = stdoutLines.at(-1);
	if (!lastLine) {
		throw new Error(`Probe produced no output\nSTDERR:\n${result.stderr}`);
	}

	return JSON.parse(lastLine) as ProbeResult;
}

describe("lazy provider module loading", () => {
	it("does not load provider SDKs when importing the root barrel", () => {
		const result = runProbe("empty");
		expect(result.loadedSpecifiers).toEqual([]);
	});

	it("loads only the Anthropic SDK when calling the root lazy wrapper", () => {
		const result = runProbe("anthropic");
		expect(result.loadedSpecifiers).toEqual(["@anthropic-ai/sdk"]);
	});

	it("loads only the Anthropic SDK when dispatching through streamSimple", () => {
		const result = runProbe("dispatch");
		expect(result.loadedSpecifiers).toEqual(["@anthropic-ai/sdk"]);
	});
});
