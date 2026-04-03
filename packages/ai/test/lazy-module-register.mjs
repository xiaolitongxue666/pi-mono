import { register } from "node:module";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { MessageChannel } from "node:worker_threads";

const dir = dirname(fileURLToPath(import.meta.url));
const hooksUrl = pathToFileURL(resolve(dir, "lazy-module-load-hooks.mjs"));

const { port1, port2 } = new MessageChannel();

globalThis.__lazyProbeLoaded = [];
port1.on("message", (msg) => {
	if (msg?.type === "record" && typeof msg.specifier === "string") {
		globalThis.__lazyProbeLoaded.push(msg.specifier);
	}
});

register(hooksUrl, {
	data: { notifyPort: port2 },
	transferList: [port2],
});
