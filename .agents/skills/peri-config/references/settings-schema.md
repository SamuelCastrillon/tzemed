# Peri v1.9.0 — Full `settings.json` Schema

Based on Peri v1.9.0 (fork of Pi coding-agent). Config at `~/.peri/settings.json`.

## Model & Thinking

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `defaultProvider` | string | — | Provider name: `"anthropic"`, `"openai"`, `"google"`, `"custom"` |
| `defaultModel` | string | — | Model ID or alias (e.g. `"sonnet"`, `"claude-sonnet-4-20250514"`) |
| `defaultThinkingLevel` | string | — | `"off"` / `"minimal"` / `"low"` / `"medium"` / `"high"` / `"xhigh"` / `"max"` |
| `hideThinkingBlock` | boolean | `false` | Hide thinking blocks in output |
| `showCacheMissNotices` | boolean | `false` | Show notices for prompt-cache misses |
| `thinkingBudgets` | object | — | Custom token budgets per thinking level |

## UI & Display

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `theme` | string | `"dark"` | `"dark"`, `"light"`, or custom theme name |
| `externalEditor` | string | `$VISUAL`→`$EDITOR`→`notepad` | Ctrl+G editor command |
| `quietStartup` | boolean | `false` | Hide startup header |
| `defaultProjectTrust` | string | `"ask"` | `"ask"` / `"always"` / `"never"` |
| `collapseChangelog` | boolean | `false` | Condensed changelog after updates |
| `enableInstallTelemetry` | boolean | `true` | Install/update version ping |
| `enableAnalytics` | boolean | `false` | Opt-in analytics |
| `doubleEscapeAction` | string | `"tree"` | `"tree"` / `"fork"` / `"none"` |
| `treeFilterMode` | string | `"default"` | `"default"` / `"no-tools"` / `"user-only"` / `"labeled-only"` / `"all"` |
| `editorPaddingX` | number | `0` | Input editor horizontal padding (0–3) |
| `outputPad` | number | `1` | Message padding (0 or 1) |
| `autocompleteMaxVisible` | number | `5` | Autocomplete dropdown items (3–20) |
| `showHardwareCursor` | boolean | `false` | Show terminal cursor for IME |

## Compaction

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `compaction.enabled` | boolean | `true` | Enable auto-compaction |
| `compaction.reserveTokens` | number | `16384` | Tokens reserved for response |
| `compaction.keepRecentTokens` | number | `20000` | Recent tokens to keep (unsummarized) |

## Retry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `retry.enabled` | boolean | `true` | Auto-retry on transient errors |
| `retry.maxRetries` | number | `3` | Max agent-level retry attempts |
| `retry.baseDelayMs` | number | `2000` | Backoff base delay |
| `retry.provider.timeoutMs` | number | SDK default | Provider request timeout |
| `retry.provider.maxRetries` | number | `0` | Provider/SDK retries |
| `retry.provider.maxRetryDelayMs` | number | `60000` | Max server-requested delay |

## Network

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `httpProxy` | string | — | Proxy URL (global only) |

## Message Delivery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `steeringMode` | string | `"one-at-a-time"` | `"all"` / `"one-at-a-time"` |
| `followUpMode` | string | `"one-at-a-time"` | `"all"` / `"one-at-a-time"` |
| `transport` | string | `"auto"` | `"sse"` / `"websocket"` / `"websocket-cached"` / `"auto"` |
| `httpIdleTimeoutMs` | number | `300000` | HTTP idle timeout (0 = disable) |
| `websocketConnectTimeoutMs` | number | `15000` | WebSocket handshake timeout |

## Shell

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `shellPath` | string | — | Custom shell path (supports `~`) |
| `shellCommandPrefix` | string | — | Prefix for every bash command |
| `npmCommand` | string[] | — | Custom npm command argv |

## Sessions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sessionDir` | string | — | Session file directory (supports `~`) |

## Model Cycling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enabledModels` | string[] | `[]` | Model patterns for Ctrl+P cycling |

## Markdown

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `markdown.codeBlockIndent` | string | `"  "` | Code block indentation |

## Resources (skills/prompts/extensions)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `packages` | array | `[]` | npm/git packages for resources |
| `extensions` | string[] | `[]` | Local extension paths |
| `skills` | string[] | `[]` | Local skill paths |
| `prompts` | string[] | `[]` | Local prompt template paths |
| `themes` | string[] | `[]` | Local theme paths |
| `enableSkillCommands` | boolean | `true` | Register `/skill:name` commands |

## Example (full)

```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-20250514",
  "defaultThinkingLevel": "medium",
  "theme": "dark",
  "compaction": {
    "enabled": true,
    "reserveTokens": 16384,
    "keepRecentTokens": 20000
  },
  "retry": {
    "enabled": true,
    "maxRetries": 3,
    "baseDelayMs": 2000
  },
  "enabledModels": ["claude-*", "gpt-4o"],
  "skills": [".agents/skills"]
}
```

## Tzemed-Specific Notes

- **Config path**: `~/.peri/settings.json` (NOT `~/.pi/agent/settings.json`)
- **Nvim integration**: `:Peri` via toggleterm at `~/.config/nvim/lua/plugins/ai.lua`
- **Keymap**: `<leader>ap` toggles Peri terminal
- **Scoop install**: `~\scoop\apps\peri\current\peri-windows-x86_64.exe`
- **API keys**: Set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in PowerShell `$PROFILE`
