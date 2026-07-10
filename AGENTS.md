# Tzemed — AI Agent Context

## Overview

Tzemed is a Windows native dev stack distro: Herdr + Neovim (LazyVim) + Peri + Starship + Gentle-ai SDD.

## Key Paths

- **Config root**: `~/.config/` (via `$env:XDG_CONFIG_HOME`)
- **Nvim config**: `~/.config/nvim/`
- **Herdr config**: `~/.config/herdr/config.toml`
- **Starship config**: `~/.config/starship.toml`
- **Peri config**: `~/.peri/settings.json`
- **Install script**: `scripts/install.ps1`
- **Entry point**: `scripts/tzemed.ps1`
- **Scoop manifest**: `scoop-bucket/tzemed.json`
- **Tests**: `tests/unit/`, `tests/e2e/`

## Stack

| Role | Tool | Config Path |
|------|------|-------------|
| Multiplexor | Herdr | `~/.config/herdr/config.toml` |
| Editor | Neovim (LazyVim) | `~/.config/nvim/` |
| AI Agent | Peri | `~/.peri/settings.json` |
| Prompt | Starship | `~/.config/starship.toml` |
| Package Manager | Scoop | `scoop-bucket/tzemed.json` |
| Workflow | Gentle-ai SDD | Engram artifact store |

## Build & Test

```powershell
# Unit tests
Invoke-Pester tests/unit/

# E2E tests
pwsh -File tests/e2e/install.E2E.ps1

# Nvim health check
pwsh -File tests/nvim-health.ps1
```

## SDD Artifacts

SDD artifacts are stored in Engram with topic keys:
- `sdd/tzemed/spec` — Requirements and scenarios
- `sdd/tzemed/design` — Architecture and architecture decisions
- `sdd/tzemed/tasks` — Implementation tasks
- `sdd/tzemed/apply-progress` — Implementation progress

## Nvim Plugin Structure

```
~/.config/nvim/
├── init.lua           # Bootstrap lazy.nvim
└── lua/
    ├── config/
    │   ├── lazy.lua       # LazyVim setup with plugin imports
    │   ├── options.lua    # Tzemed-specific vim options
    │   ├── keymaps.lua    # Custom keymaps
    │   └── autocmds.lua   # Autocommands
    └── plugins/
        ├── editor.lua     # telescope, which-key, gitsigns
        ├── ui.lua         # noice, dashboard, catppuccin
        ├── lsp.lua        # mason, lspconfig, nvim-cmp
        ├── ai.lua         # Peri integration via toggleterm
        └── tzemed.lua     # indent-blankline, todo-comments, fugitive
```

## Peri Integration

- Command `:Peri` opens Peri in a floating terminal via `toggleterm.nvim`
- Keymap `<leader>ap` toggles Peri
- Peri config at `~/.peri/settings.json` has `"editor": "nvim"`
- No AI model is shipped — Peri's first-launch wizard handles provider setup

## Herdr Layout

3-pane default layout:
- Left (60%): nvim
- Right-top (70%): PowerShell terminal
- Right-bottom (30%): Peri AI agent

## Environment Variables

| Variable | Value | Notes |
|----------|-------|-------|
| `XDG_CONFIG_HOME` | `%USERPROFILE%\.config` | Set in $PROFILE via marker block |

## Skills

Skills under `.agents/skills/` provide LLM guidance for project-specific patterns. Each skill is based on official documentation for the exact version in use.

| Skill | Path | When it loads |
|-------|------|---------------|
| `herdr-config` | `.agents/skills/herdr-config/SKILL.md` | Editing Herdr `config.toml` or keybinding questions |
| `nvim-config` | `.agents/skills/nvim-config/SKILL.md` | Editing Neovim config (`init.lua`, `lua/config/*`, `lua/plugins/*`) |
| `peri-config` | `.agents/skills/peri-config/SKILL.md` | Editing Peri `settings.json` or provider/model questions |
| `starship-config` | `.agents/skills/starship-config/SKILL.md` | Editing `starship.toml` or prompt module questions |
| `scoop-bucket` | `.agents/skills/scoop-bucket/SKILL.md` | Editing `bucket/tzemed.json`, `install.ps1`, or release questions |

## Windows Requirements

- Windows 10 1809 (build 17763) or later
- PowerShell 7+
- Scoop package manager
