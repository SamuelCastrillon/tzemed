# Architecture

## Overview

Tzemed is a **Windows native dev stack distro** — an opinionated, installable bundle of tools for AI-assisted software development on Windows. It combines Herdr (multiplexor), Neovim (editor), Peri (AI agent), and Starship (prompt) into a single cohesive stack.

## Design Principles

1. **Windows native** — no WSL, no virtualization. Everything runs on Windows natively.
2. **Install and use** — a single `scoop install tzemed` commands sets up the entire stack.
3. **Opinionated** — one editor, one multiplexor, one AI agent. No configuration menus.
4. **Portable configs** — all configs live in `~/.config/<tool>/` via `XDG_CONFIG_HOME`, enabling future cross-platform support.
5. **Idempotent** — safe to re-run installer and entry point; no duplicate state.

## Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Multiplexor | **Herdr** | Agent-aware workspace with persistent sessions |
| Editor | **Neovim** (LazyVim) | Full IDE with LSP, completion, Git integration |
| AI Agent | **Peri** | Multi-LLM agent with MCP support |
| Shell Prompt | **Starship** | Fast, cross-platform prompt with Git/runtime info |
| Package Manager | **Scoop** | Windows package manager for Tzemed distribution |

## Installation Flow

```
User
  │
  ▼
scoop install tzemed  ──→ tzemed.json post_install calls scripts/install.ps1
  │
  ▼
install.ps1
  │
  ├── Check-Requirements
  │     - Windows ≥10.0.17763 (1809)
  │     - Scoop installed
  │     - Execution policy not Restricted
  │     - All deps present (herdr, nvim, peri, starship)
  │
  ├── Backup-TzemedState
  │     - Creates Compress-Archive backup of existing configs
  │     - Backup path: ~/.config/tzemed.backup/YYYYMMDD-HHMMSS.zip
  │
  ├── Copy-Configs
  │     - config/nvim/           → ~/.config/nvim/
  │     - config/herdr/config.toml → ~/.config/herdr/config.toml
  │     - config/peri/settings.json → ~/.peri/settings.json
  │     - config/starship.toml   → ~/.config/starship.toml
  │
  ├── Set-Profile
  │     - Adds marker block (# === TZEMED BEGIN/END ===) to $PROFILE
  │     - Sets $env:XDG_CONFIG_HOME = "$HOME\.config"
  │     - Idempotent: skips if marker block exists
  │
  └── Verify-Binaries
        - Runs herdr --version, nvim --version, peri --version, starship --version
        - ALL pass → success
        - ANY fail → Restore-Backup → rollback
```

## Runtime Flow

```
PowerShell prompt (Starship, ~/.config/starship.toml)
        │
        ▼
    herdr (~/.config/herdr/config.toml)
        │
  ┌─────┼─────────┐
  │     │         │
  ▼     ▼         ▼
nvim  terminal   peri (~/.peri/settings.json)
(LazyVim)
  └── :Peri command ──→ Floating terminal ──→ peri --cwd <dir>
```

## File Layout

```
~/.config/
├── nvim/
│   ├── init.lua
│   └── lua/
│       ├── config/
│       │   ├── lazy.lua         # LazyVim bootstrap
│       │   ├── options.lua      # Tzemed-specific options
│       │   ├── keymaps.lua      # Custom keymaps
│       │   └── autocmds.lua     # Autocommands
│       └── plugins/
│           ├── editor.lua       # telescope, which-key, gitsigns
│           ├── ui.lua           # noice, dashboard, catppuccin
│           ├── lsp.lua          # mason + lspconfig + cmp
│           ├── ai.lua           # Peri integration via toggleterm
│           └── tzemed.lua       # indent-blankline, todo-comments, fugitive
├── herdr/
│   └── config.toml              # 3-pane layout
├── starship.toml                # Git, runtimes, command duration
~/.peri/
└── settings.json                # Peri config (no model, editor: nvim)
```

## Backup & Recovery

- **Backup**: all-or-nothing `Compress-Archive` snapshot of all existing configs
- **Restore**: on any binary verification failure, backup is extracted to restore original state
- **Recovery marker**: `~/.config/tzemed.init` is removed on rollback, ensuring re-init on next run

## Environment Variables

| Variable | Value | Set by |
|----------|-------|--------|
| `XDG_CONFIG_HOME` | `%USERPROFILE%\.config` | `Set-Profile` in install.ps1 |
| `PERI_CONFIG_DIR` | `%USERPROFILE%\.peri` | Peri default, config copied to this path |

## Idempotency

- `~/.config/tzemed.init` marker file prevents redundant initialization
- `$PROFILE` marker block (`# === TZEMED BEGIN/END ===`) enables clean re-runs
- `Set-Profile` checks for pre-existing `$env:XDG_CONFIG_HOME` before modifying
