# Peri Setup

## Overview

[Peri](https://github.com/KonghaYao/peri) is a Rust-based AI agent (≈13MB, ≈50MB RAM) that supports multiple LLM providers. Tzemed integrates Peri as the default AI agent in the development stack.

## Configuration

**Path**: `~/.peri/settings.json`

Tzemed ships with a minimal Peri configuration:

```json
{
  "$schema": "https://raw.githubusercontent.com/KonghaYao/peri/main/schema.json",
  "config": {
    "editor": "nvim",
    "providers": [],
    "notifications": true,
    "telemetry": false
  }
}
```

### Why no model is configured

Tzemed does **not** ship with a default AI provider/model. Peri's first-launch wizard guides you through:

1. Selecting an LLM provider (DeepSeek, OpenAI, Anthropic, etc.)
2. Entering your API key
3. Configuring the default model

This ensures you use **your own** API keys and preferred provider rather than a hardcoded default.

## Neovim Integration

Peri is accessible from Neovim via:

| Command | Action |
|---------|--------|
| `:Peri` | Open Peri in a floating terminal |
| `<leader>ap` | Toggle Peri floating terminal |

The integration uses `toggleterm.nvim` to spawn Peri as a floating terminal connected to the current buffer's working directory.

### How it works

1. `:Peri` command creates a floating terminal running `peri --cwd <current-directory>`
2. Peri can read the active buffer and open files in nvim
3. Press `Esc` in the terminal to enter Normal mode
4. Use `:q` or toggle with `<leader>ap` to close

## First Launch

1. Run `peri` in any terminal
2. Follow the interactive setup wizard to configure your provider
3. API key is stored securely by Peri (not in the Tzemed config)
4. Once configured, Peri is ready to use

## Troubleshooting

### Peri doesn't find its config
- Verify `~/.peri/settings.json` exists
- If missing, re-run `tzemed` to deploy configs
- Or copy manually from `config/peri/settings.json` in the Tzemed install

### Peri can't open files in nvim
- Ensure `"editor": "nvim"` is set in `~/.peri/settings.json`
- Verify `nvim` is in PATH: `nvim --version`
- Peri uses the system PATH to find nvim

### Want to change model/provider
- Run `peri configure` to re-run the setup wizard
- Or edit `~/.peri/settings.json` directly to add providers
