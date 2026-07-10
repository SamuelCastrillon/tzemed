---
name: peri-config
description: "Trigger: peri, AI agent, settings.json, provider, model. Guide for Peri v1.9.0 configuration and Tzemed integration."
license: Apache-2.0
metadata:
  author: "SamuelCastrillon"
  version: "1.0"
---

## Activation Contract

Load when editing `~/.peri/settings.json`, or when asked about Peri provider/model setup, CLI flags, or Tzemed nvim integration (`:Peri`, `<leader>ap`).

## Hard Rules

1. **Config**: Global at `~/.peri/settings.json`. Project overrides at `.peri/settings.json` in project root. No reload command — restart Peri.
2. **API keys** go in env vars (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`), NEVER in `settings.json`.
3. **First launch** runs a wizard — do NOT scaffold `settings.json` manually before first run.
4. **Project trust**: `defaultProjectTrust` (`"ask"`/`"always"`/`"never"`) controls loading of project-local `.peri/settings.json`. Global only.

## Decision Gates

| Need | Action |
|------|--------|
| Change provider/model | Edit `defaultProvider` / `defaultModel` in settings |
| Set thinking level | `defaultThinkingLevel`: `off`/`minimal`/`low`/`medium`/`high`/`xhigh`/`max` |
| Add skills/prompts | Add paths to `skills` / `prompts` arrays |
| Disable auto-compaction | Set `compaction.enabled: false` |
| Set session dir | `sessionDir` (supports `~` and relative paths) |
| Cycle models at runtime | `Ctrl+T` / `Ctrl+Shift+T` |
| Open Peri in nvim | `:Peri` or `<leader>ap` |

## Execution Steps

1. Check `Test-Path ~/.peri/settings.json`. If missing, run `peri` once for first-launch wizard — do NOT scaffold.
2. Edit `~/.peri/settings.json` directly or use `/settings` in interactive mode.
3. Set provider: `"defaultProvider": "anthropic"` (or `openai`, `google`, `custom`). API keys in env vars only.
4. Set model: `"defaultModel": "claude-sonnet-4-20250514"` or alias `"sonnet"`.
5. For Tzemed: ensure `~/.config/nvim/lua/plugins/ai.lua` calls `peri-windows-x86_64.exe` via toggleterm.
6. Restart Peri to pick up changes.
7. Use `--approve` for HITL mode, `--model` to override per session.

## Output Contract

Return the exact JSON snippet for `~/.peri/settings.json` and confirm which settings changed. For first-time setup, guide through the wizard instead of providing a pre-built config.

## References

- `references/settings-schema.md` — full schema with defaults
- `~/.peri/settings.json` — live config
- `~/.config/nvim/lua/plugins/ai.lua` — Tzemed nvim toggleterm integration
