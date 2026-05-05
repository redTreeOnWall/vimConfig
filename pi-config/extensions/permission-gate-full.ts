/**
 * Permission Gate Full Extension
 *
 * Asks for confirmation before executing any tool by default.
 * Supports configuration: all operations / dangerous only / none.
 */

import type { ExtensionAPI, ToolCallEvent, ExtensionContext } from "@mariozechner/pi-coding-agent";
import * as pathModule from "node:path";

// Configuration options
interface Config {
	// Confirm level: "all" = all operations, "smart" = write only, "dangerous" = dangerous only, "none" = no confirmation
	confirmLevel: "all" | "smart" | "dangerous" | "none";
	// Dangerous command patterns (bash)
	dangerousPatterns: RegExp[];
	// Dangerous file path patterns (write/edit)
	dangerousPaths: string[];
	// Whitelist commands (auto-allow, no prompt)
	whitelist: string[];
}

const defaultConfig: Config = {
	confirmLevel: "smart", // Default: only confirm write operations
	dangerousPatterns: [
		/\brm\s+(-rf?|--recursive)/i, // rm -rf
		/\bsudo\b/i, // sudo
		/\b(chmod|chown)\b.*777/i, // chmod 777
		/\bdd\b.*of=\//i, // dd to disk
		/\bmv\b.*\/(bin|sbin|lib|usr)/i, // move system files
		/\bcurl\b.*\|.*sh/i, // curl | sh
		/\bwget\b.*-.*O-.*\|.*sh/i, // wget | sh
		/\bdocker\b.*rm/i, // docker rm
		/\bkubectl\b.*delete/i, // kubectl delete
		/\bgit\s+reset\s+--hard/i, // git reset --hard
		/\bgit\s+clean\s+-fd/i, // git clean -fd
	],
	dangerousPaths: [
		".env",
		".git/",
		"node_modules/",
		"/etc/",
		"/usr/",
		"/bin/",
		"/sbin/",
		"package.json",
		"package-lock.json",
		"yarn.lock",
		"pnpm-lock.yaml",
		"Cargo.lock",
		"Gemfile.lock",
	],
	whitelist: ["ls", "pwd", "echo", "cat", "head", "tail", "grep", "find"],
};

// Remembered choices cache
interface RememberedChoice {
	choice: "allow" | "deny";
	expiresAt: number;
}

export default function (pi: ExtensionAPI) {
	// Restore config from session
	let config: Config = { ...defaultConfig };
	let isEnabled = true; // Gate enabled by default
	const rememberedChoices = new Map<string, RememberedChoice>();

	// Restore config and remembered choices on session start
	pi.on("session_start", async (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();
		for (const entry of entries) {
			if (entry.type === "custom" && entry.customType === "permission-gate-config") {
				config = { ...defaultConfig, ...(entry.data as Partial<Config>) };
			}
			if (entry.type === "custom" && entry.customType === "permission-gate-remembered") {
				const data = entry.data as { key: string; choice: "allow" | "deny"; expiresAt: number };
				if (Date.now() < data.expiresAt) {
					rememberedChoices.set(data.key, { choice: data.choice, expiresAt: data.expiresAt });
				}
			}
		}
	});

	// Clear remembered choices on session shutdown
	pi.on("session_shutdown", async () => {
		rememberedChoices.clear();
	});

	// Register command to toggle confirm level
	pi.registerCommand("guard", {
		description: "Toggle guard level: /guard [all|smart|dangerous|none]",
		handler: async (args, ctx) => {
			const level = (args?.trim() as Config["confirmLevel"]) || "smart";

			if (!["all", "smart", "dangerous", "none"].includes(level)) {
				ctx.ui.notify("Invalid option. Usage: /guard all|smart|dangerous|none", "error");
				return;
			}

			config.confirmLevel = level;

			// Save config to session
			pi.appendEntry("permission-gate-config", { confirmLevel: level });

			ctx.ui.notify(`Guard level changed to: ${level}`, "success");
		},
	});

	// Register command to toggle gate on/off
	pi.registerCommand("gate", {
		description: "Toggle permission gate: /gate [on|off|status]",
		handler: async (args, ctx) => {
			const subcmd = args?.trim().toLowerCase() || "status";

			if (subcmd === "off" || subcmd === "disable") {
				isEnabled = false;
				ctx.ui.notify("Permission gate: DISABLED (all tools allowed)", "warning");
			} else if (subcmd === "on" || subcmd === "enable") {
				isEnabled = true;
				ctx.ui.notify("Permission gate: ENABLED", "success");
			} else {
				ctx.ui.notify(`Permission gate: ${isEnabled ? "ENABLED" : "DISABLED"}`, "info");
			}
		},
	});

	// Intercept tool calls
	pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
		// Skip if gate is disabled
		if (!isEnabled) {
			return undefined;
		}

		// If set to no confirmation, allow directly
		if (config.confirmLevel === "none") {
			return undefined;
		}

		// In non-interactive mode, block based on level
		if (!ctx.hasUI) {
			if (config.confirmLevel === "all") {
				return { block: true, reason: "Permission gate: confirmation required in interactive mode only" };
			}
			return undefined;
		}

		// Handle based on tool type
		switch (event.toolName) {
			case "bash":
				return handleBash(event, ctx, config);
			case "write":
				return handleWrite(event, ctx, config);
			case "edit":
				return handleEdit(event, ctx, config);
			case "read":
				return handleRead(event, ctx, config);
			default:
				// Other tools (e.g., custom extension tools)
				return handleGenericTool(event, ctx, config);
		}
	});

	// Handle bash commands
	async function handleBash(
		event: ToolCallEvent,
		ctx: ExtensionContext,
		config: Config,
	): Promise<{ block: true; reason: string } | undefined> {
		const command = (event.input.command as string) || "";

		// Check if dangerous command
		const isDangerous = config.dangerousPatterns.some((p) => p.test(command));

		// If set to dangerous only and not dangerous, allow directly
		if (config.confirmLevel === "dangerous" && !isDangerous) {
			return undefined;
		}

		// In smart mode, allow read-only commands
		const readOnlyCommands = ["ls", "cat", "head", "tail", "grep", "find", "pwd", "echo", "which", "type", "file", "stat", "du", "df", "ps", "top", "htop", "whoami", "uname", "date", "cal"];
		const commandType = command.trim().split(/\s+/)[0];
		const isReadOnly = readOnlyCommands.includes(commandType);
		if (config.confirmLevel === "smart" && isReadOnly && !isDangerous) {
			return undefined;
		}

		// Check whitelist (legacy behavior for non-smart modes)
		const isWhitelisted = config.whitelist.some((w) => command.trim().startsWith(w));
		if (isWhitelisted && config.confirmLevel !== "all") {
			return undefined;
		}

		// Check remembered choice (exact match first, then category)
		const exactKey = `bash:${command}`;
		const typeKey = `bash-type:${commandType}`;
		const remembered = getRememberedChoice(exactKey) || getRememberedChoice(typeKey);
		if (remembered) {
			if (remembered === "allow") return undefined;
			return { block: true, reason: "Blocked by previous user choice" };
		}

		// Build confirmation message
		const dangerEmoji = isDangerous ? "⚠️ " : "";
		const dangerLabel = isDangerous ? " [DANGEROUS]" : "";

		// Use select for all commands with flexible options
		const options = [
			"✓ Allow once",
			"✓ Allow & Remember this exact command",
			`✓ Allow & Remember all "${commandType}" commands`,
			"✗ Block",
		];
		const choice = await ctx.ui.select(`${dangerEmoji}Execute Bash command${dangerLabel}\n\n${command}`, options);

		switch (choice) {
			case "✓ Allow once":
				return undefined;
			case "✓ Allow & Remember this exact command":
				rememberChoice(exactKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case `✓ Allow & Remember all "${commandType}" commands`:
				rememberChoice(typeKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case "✗ Block":
				return { block: true, reason: "Blocked by user" };
			default:
				return { block: true, reason: "Blocked by user" };
		}
	}

	// Handle write operations
	async function handleWrite(
		event: ToolCallEvent,
		ctx: ExtensionContext,
		config: Config,
	): Promise<{ block: true; reason: string } | undefined> {
		const path = (event.input.path as string) || "";
		const content = (event.input.content as string)?.slice(0, 200) || "";

		// Check if dangerous path
		const isDangerous = config.dangerousPaths.some((p) => path.includes(p));

		// If set to dangerous only and not dangerous, allow directly
		if (config.confirmLevel === "dangerous" && !isDangerous) {
			return undefined;
		}

		// Get directory for category-based remembering
		const dir = pathModule.dirname(path);

		// Check remembered choice (exact match first, then directory)
		const exactKey = `write:${path}`;
		const dirKey = `write-dir:${dir}/`;
		const remembered = getRememberedChoice(exactKey) || getRememberedChoice(dirKey);
		if (remembered) {
			if (remembered === "allow") return undefined;
			return { block: true, reason: "Blocked by previous user choice" };
		}

		const dangerEmoji = isDangerous ? "⚠️ " : "";
		const dangerLabel = isDangerous ? " [PROTECTED PATH]" : "";

		const options = [
			"✓ Allow once",
			"✓ Allow & Remember this exact file",
			`✓ Allow & Remember all files in "${dir}/"`,
			"✗ Block",
		];
		const choice = await ctx.ui.select(
			`${dangerEmoji}Write file${dangerLabel}\nPath: ${path}\n\nContent preview:\n${content}...`,
			options,
		);

		switch (choice) {
			case "✓ Allow once":
				return undefined;
			case "✓ Allow & Remember this exact file":
				rememberChoice(exactKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case `✓ Allow & Remember all files in "${dir}/"`:
				rememberChoice(dirKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case "✗ Block":
				return { block: true, reason: `Blocked write to: ${path}` };
			default:
				return { block: true, reason: `Blocked write to: ${path}` };
		}
	}

	// Handle edit operations
	async function handleEdit(
		event: ToolCallEvent,
		ctx: ExtensionContext,
		config: Config,
	): Promise<{ block: true; reason: string } | undefined> {
		const path = (event.input.path as string) || "";
		const oldText = (event.input.oldText as string)?.slice(0, 100) || "";
		const newText = (event.input.newText as string)?.slice(0, 100) || "";

		// Check if dangerous path
		const isDangerous = config.dangerousPaths.some((p) => path.includes(p));

		// If set to dangerous only and not dangerous, allow directly
		if (config.confirmLevel === "dangerous" && !isDangerous) {
			return undefined;
		}

		// Get directory for category-based remembering
		const dir = pathModule.dirname(path);

		// Check remembered choice (exact match first, then directory)
		const exactKey = `edit:${path}`;
		const dirKey = `edit-dir:${dir}/`;
		const remembered = getRememberedChoice(exactKey) || getRememberedChoice(dirKey);
		if (remembered) {
			if (remembered === "allow") return undefined;
			return { block: true, reason: "Blocked by previous user choice" };
		}

		const dangerEmoji = isDangerous ? "⚠️ " : "";
		const dangerLabel = isDangerous ? " [PROTECTED PATH]" : "";

		const options = [
			"✓ Allow once",
			"✓ Allow & Remember this exact file",
			`✓ Allow & Remember all files in "${dir}/"`,
			"✗ Block",
		];
		const choice = await ctx.ui.select(
			`${dangerEmoji}Edit file${dangerLabel}\nPath: ${path}\n\nOriginal:\n${oldText}...\n\nChange to:\n${newText}...`,
			options,
		);

		switch (choice) {
			case "✓ Allow once":
				return undefined;
			case "✓ Allow & Remember this exact file":
				rememberChoice(exactKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case `✓ Allow & Remember all files in "${dir}/"`:
				rememberChoice(dirKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case "✗ Block":
				return { block: true, reason: `Blocked edit to: ${path}` };
			default:
				return { block: true, reason: `Blocked edit to: ${path}` };
		}
	}

	// Handle read operations
	async function handleRead(
		event: ToolCallEvent,
		ctx: ExtensionContext,
		config: Config,
	): Promise<{ block: true; reason: string } | undefined> {
		const path = (event.input.path as string) || "";

		// Check if dangerous path
		const isDangerous = config.dangerousPaths.some((p) => path.includes(p));

		// Read is low risk, only prompt for dangerous paths
		if (!isDangerous) {
			return undefined;
		}

		// Get directory for category-based remembering
		const dir = pathModule.dirname(path);

		// Check remembered choice (exact match first, then directory)
		const exactKey = `read:${path}`;
		const dirKey = `read-dir:${dir}/`;
		const remembered = getRememberedChoice(exactKey) || getRememberedChoice(dirKey);
		if (remembered) {
			if (remembered === "allow") return undefined;
			return { block: true, reason: "Blocked by previous user choice" };
		}

		const dangerEmoji = "⚠️ ";
		const dangerLabel = " [PROTECTED PATH]";

		const options = [
			"✓ Allow once",
			"✓ Allow & Remember this exact file",
			`✓ Allow & Remember all files in "${dir}/"`,
			"✗ Block",
		];
		const choice = await ctx.ui.select(
			`${dangerEmoji}Read file${dangerLabel}\nPath: ${path}`,
			options,
		);

		switch (choice) {
			case "✓ Allow once":
				return undefined;
			case "✓ Allow & Remember this exact file":
				rememberChoice(exactKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case `✓ Allow & Remember all files in "${dir}/"`:
				rememberChoice(dirKey, "allow", Number.MAX_SAFE_INTEGER);
				return undefined;
			case "✗ Block":
				return { block: true, reason: `Blocked read from: ${path}` };
			default:
				return { block: true, reason: `Blocked read from: ${path}` };
		}
	}

	// Handle other generic tools
	async function handleGenericTool(
		event: ToolCallEvent,
		ctx: ExtensionContext,
		config: Config,
	): Promise<{ block: true; reason: string } | undefined> {
		// Only prompt for other tools in "all" mode
		if (config.confirmLevel !== "all") {
			return undefined;
		}

		const toolName = event.toolName;
		const input = JSON.stringify(event.input).slice(0, 200);

		const confirmed = await ctx.ui.confirm(
			`Execute tool: ${toolName}`,
			`Args: ${input}...`,
		);

		if (!confirmed) {
			return { block: true, reason: `Blocked ${toolName} tool` };
		}
		return undefined;
	}

	// Helper: get remembered choice
	function getRememberedChoice(cacheKey: string): "allow" | "deny" | undefined {
		const remembered = rememberedChoices.get(cacheKey);
		if (!remembered) return undefined;
		if (Date.now() > remembered.expiresAt) {
			rememberedChoices.delete(cacheKey);
			return undefined;
		}
		return remembered.choice;
	}

	// Helper: remember choice (persist to session)
	function rememberChoice(cacheKey: string, choice: "allow" | "deny", durationMs: number) {
		const expiresAt = Date.now() + durationMs;
		rememberedChoices.set(cacheKey, { choice, expiresAt });
		// Persist to session so it survives reloads
		pi.appendEntry("permission-gate-remembered", { key: cacheKey, choice, expiresAt });
	}
}
